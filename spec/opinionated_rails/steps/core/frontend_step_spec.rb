# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe OpinionatedRails::Steps::Core::FrontendStep do
  def build_context(answers, app_path: Dir.mktmpdir, app_type: :full_stack)
    ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
    ctx.set_output(:app_type, { app_type: app_type })
    ctx
  end

  it "has the expected id, tier, and prompts" do
    expect(described_class.id).to eq(:frontend)
    expect(described_class.tier).to eq(:core)
    expect(described_class.prompts).to be_a(String)
  end

  it "is skipped for API-only apps and resolves to :none" do
    ctx = build_context([], app_type: :api_only)
    step = described_class.new
    expect(step.if_condition(ctx)).to be false
    step.generate(ctx)
    expect(ctx.output(:frontend)).to eq({ frontend: :none })
  end

  it "defaults to Stimulus+Hotwire" do
    ctx = build_context([ "" ])
    step = described_class.new
    step.prompt(ctx)
    expect(ctx.get(:frontend)).to eq(:stimulus_hotwire)
  end

  it "prompts for bundler when React is chosen" do
    ctx = build_context([ "2", "webpack" ])
    step = described_class.new
    step.prompt(ctx)
    expect(ctx.get(:frontend)).to eq(:react)
    expect(ctx.get(:bundler)).to eq(:webpack)
  end

  it "writes React files and updates package.json" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "2", "" ], app_path: tmp)
      File.write(
        File.join(tmp, "package.json"),
        JSON.pretty_generate({ "dependencies" => { "esbuild" => "1.0" }, "scripts" => { "build" => "esbuild app/javascript/*.*" } })
      )
      FileUtils.mkdir_p(File.join(tmp, "app/javascript"))
      File.write(File.join(tmp, "app/javascript/application.js"), "// default")

      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:frontend)).to eq({ frontend: :react, bundler: :esbuild })
      expect(File).not_to exist(File.join(tmp, "app/javascript/application.js"))
      expect(File).to exist(File.join(tmp, "app/javascript/application.jsx"))
      expect(File).to exist(File.join(tmp, "app/javascript/router.jsx"))
      expect(File).to exist(File.join(tmp, "app/javascript/images"))
      expect(File).to exist(File.join(tmp, "jsconfig.json"))
      expect(File.read(File.join(tmp, "package.json"))).to include("react-dom")
      expect(File.read(File.join(tmp, "package.json"))).to include("--alias:@=app/javascript")
    end
  end

  def generate_react(tmp, bundler_choice, package)
    ctx = build_context([ "2", bundler_choice ], app_path: tmp)
    File.write(File.join(tmp, "package.json"), JSON.pretty_generate(package))
    FileUtils.mkdir_p(File.join(tmp, "app/javascript"))
    File.write(File.join(tmp, "app/javascript/application.js"), "// default")
    File.write(File.join(tmp, "webpack.config.js"), "// rails default") if bundler_choice == "webpack"

    step = described_class.new
    step.prompt(ctx)
    step.generate(ctx)
    ctx
  end

  it "warns that the @ alias is editor-only for bun" do
    Dir.mktmpdir do |tmp|
      ctx = generate_react(tmp, "bun", { "scripts" => { "build" => "bun build" } })

      expect(ctx.shell.messages).to include(a_string_matching(/editor\/TypeScript tooling only/))
      expect(File.read(File.join(tmp, "package.json"))).not_to include("--alias")
    end
  end

  it "does not offer rollup, whose Rails config cannot build the JSX the React step writes" do
    expect(described_class::BUNDLERS).to eq(%w[esbuild bun webpack])
  end

  describe "webpack" do
    it "adds Babel, a .jsx entry and the @ alias so the JSX actually builds" do
      Dir.mktmpdir do |tmp|
        ctx = generate_react(tmp, "webpack", { "scripts" => { "build" => "webpack --config webpack.config.js" } })

        package = JSON.parse(File.read(File.join(tmp, "package.json")))
        expect(package["devDependencies"].keys).to include("@babel/core", "@babel/preset-env", "@babel/preset-react", "babel-loader")
        config = File.read(File.join(tmp, "webpack.config.js"))
        expect(config).to include("./app/javascript/application.jsx", "babel-loader", '".jsx"', 'alias: { "@"')
        expect(File.read(File.join(tmp, "babel.config.json"))).to include("@babel/preset-react")
        expect(ctx.shell.messages).not_to include(a_string_matching(/editor\/TypeScript tooling only/))
      end
    end
  end
  it "imports React in every JSX file, since esbuild's classic JSX transform needs it in scope" do
    Dir.mktmpdir do |tmp|
      generate_react(tmp, "esbuild", { "scripts" => { "build" => "esbuild app/javascript/*.*" } })

      %w[ application.jsx router.jsx ].each do |file|
        expect(File.read(File.join(tmp, "app/javascript", file))).to include('import React from "react";')
      end
    end
  end
  describe "bun" do
    let(:rails_bun_config) do
      File.read(Gem::Specification.find_by_name("jsbundling-rails").gem_dir + "/lib/install/bun/bun.config.js")
    rescue Gem::MissingSpecError
      "const config = {\n  entrypoints: [\"app/javascript/application.js\"],\n};\n"
    end

    def generate_bun(tmp, config)
      File.write(File.join(tmp, "bun.config.js"), config) if config
      generate_react(tmp, "bun", { "scripts" => { "build" => "bun bun.config.js" } })
    end

    it "points Rails' bun config at application.jsx, which is what the React step writes" do
      Dir.mktmpdir do |tmp|
        generate_bun(tmp, rails_bun_config)

        config = File.read(File.join(tmp, "bun.config.js"))
        expect(config).to include('entrypoints: ["app/javascript/application.jsx"]')
        expect(config).not_to include("application.js\"")
      end
    end

    it "is idempotent" do
      Dir.mktmpdir do |tmp|
        generate_bun(tmp, rails_bun_config)
        first = File.read(File.join(tmp, "bun.config.js"))
        ctx = generate_react(tmp, "bun", { "scripts" => { "build" => "bun bun.config.js" } })

        expect(File.read(File.join(tmp, "bun.config.js"))).to eq(first)
        expect(ctx.shell.messages.grep(/could not find/)).to be_empty
      end
    end

    it "warns, instead of silently leaving the build broken, when Rails' config has changed" do
      Dir.mktmpdir do |tmp|
        ctx = generate_bun(tmp, "export default {}\n")

        expect(ctx.shell.messages.grep(/Warning: could not find .* in bun.config.js/)).not_to be_empty
        expect(File.read(File.join(tmp, "bun.config.js"))).to eq("export default {}\n")
      end
    end
  end
end
