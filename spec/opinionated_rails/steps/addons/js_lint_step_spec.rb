# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe OpinionatedRails::Steps::Addons::JsLintStep do
  def build_context(answers, app_path: Dir.mktmpdir, frontend: :stimulus_hotwire)
    ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
    ctx.set_output(:frontend, { frontend: frontend })
    ctx
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:js_lint)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([ :frontend ])
    expect(described_class.prompts).to be_a(String)
  end

  it "is skipped when there is no frontend" do
    ctx = build_context([], frontend: :none)
    step = described_class.new
    expect(step.if_condition(ctx)).to be false
    step.generate(ctx)
    expect(ctx.output(:js_lint)).to eq({ js_lint: false })
  end

  it "writes plain ESLint config for Stimulus" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp, frontend: :stimulus_hotwire)
      File.write(File.join(tmp, "package.json"), JSON.pretty_generate({}))

      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:js_lint)).to eq({ js_lint: true, js_lint_tool: :eslint })
      expect(File).to exist(File.join(tmp, ".eslintrc.json"))
      expect(File.read(File.join(tmp, ".eslintrc.json"))).not_to include("react")
      expect(File.read(File.join(tmp, "package.json"))).to include("lint:js")
    end
  end

  it "writes React ESLint config and dev deps" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "yes" ], app_path: tmp, frontend: :react)
      File.write(File.join(tmp, "package.json"), JSON.pretty_generate({ "dependencies" => { "react" => "18.2.0" } }))

      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:js_lint)).to eq({ js_lint: true, js_lint_tool: :eslint })
      expect(File.read(File.join(tmp, ".eslintrc.json"))).to include("plugin:react/recommended")
      expect(File.read(File.join(tmp, "package.json"))).to include("eslint-plugin-react")
    end
  end

  it "can be disabled" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "no" ], app_path: tmp, frontend: :stimulus_hotwire)

      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:js_lint)).to eq({ js_lint: false })
      expect(File).not_to exist(File.join(tmp, ".eslintrc.json"))
    end
  end
end
