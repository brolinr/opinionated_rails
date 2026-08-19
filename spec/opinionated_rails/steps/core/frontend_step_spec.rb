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

  it "warns when a non-esbuild bundler is chosen" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "2", "rollup" ], app_path: tmp)
      File.write(
        File.join(tmp, "package.json"),
        JSON.pretty_generate({ "dependencies" => { "rollup" => "1.0" }, "scripts" => { "build" => "rollup -c" } })
      )
      FileUtils.mkdir_p(File.join(tmp, "app/javascript"))
      File.write(File.join(tmp, "app/javascript/application.js"), "// default")

      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.shell.messages).to include(a_string_matching(/editor\/TypeScript tooling only/))
      expect(File.read(File.join(tmp, "package.json"))).not_to include("--alias")
    end
  end
end
