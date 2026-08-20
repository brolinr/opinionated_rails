# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe OpinionatedRails::Steps::Addons::CiStep do
  def build_context(answers, app_path: Dir.mktmpdir, test_framework: :minitest, js_lint: false)
    ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
    ctx.set_output(:testing, { test_framework: test_framework })
    ctx.set_output(:js_lint, { js_lint: js_lint }) unless js_lint.nil?
    ctx
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:ci)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([ :rubocop, :testing ])
    expect(described_class.prompts).to be_a(String)
  end

  it "is on by default and writes a valid workflow file" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:ci)).to eq({ ci: true })

      path = File.join(tmp, ".github/workflows/ci.yml")
      expect(File).to exist(path)
      parsed = YAML.safe_load_file(path, permitted_classes: [ Symbol ], aliases: true)
      expect(parsed["jobs"]).to have_key("test")
      expect(parsed["jobs"]).to have_key("rubocop")
    end
  end

  it "uses bundle exec rspec for the RSpec test job" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp, test_framework: :rspec)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      content = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(content).to include("bundle exec rspec")
    end
  end

  it "uses bin/rails test for the Minitest test job" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp, test_framework: :minitest)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      content = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(content).to include("bin/rails test")
    end
  end

  it "includes a js_lint job only when js_lint output is true" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp, js_lint: true)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      content = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(content).to include("js_lint:")
      expect(content).to include("npm run lint:js")
    end
  end

  it "omits the js_lint job when js_lint output is absent" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp, js_lint: nil)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      content = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(content).not_to include("js_lint:")
    end
  end

  it "writes no workflow file when disabled" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "no" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:ci)).to eq({ ci: false })
      expect(File).not_to exist(File.join(tmp, ".github/workflows/ci.yml"))
    end
  end
end
