# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::VcrStep do
  def build_context(answers, app_path: Dir.mktmpdir, test_framework: :rspec)
    ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
    ctx.set_output(:testing, { test_framework: test_framework })
    ctx
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:vcr)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([ :testing ])
    expect(described_class.prompts).to be_a(String)
  end

  it "always applies regardless of test framework" do
    expect(described_class.new.if_condition(build_context([], test_framework: :minitest))).to be true
    expect(described_class.new.if_condition(build_context([], test_framework: :rspec))).to be true
  end

  it "is off by default" do
    ctx = build_context([ "" ])
    step = described_class.new
    step.prompt(ctx)
    step.generate(ctx)

    expect(ctx.output(:vcr)).to eq({ vcr: false })
    expect(File).not_to exist(File.join(ctx.app_path, "spec/support/vcr.rb"))
  end

  it "installs VCR for RSpec, wiring rails_helper.rb and adding Gemfile gems" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "yes" ], app_path: tmp, test_framework: :rspec)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:vcr)).to eq({ vcr: true })

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to match(/group :test do\n\s+gem "vcr", "6\.2\.0"\n\s+gem "webmock", "3\.23\.1"\n/)

      vcr_config = File.read(File.join(tmp, "spec/support/vcr.rb"))
      expect(vcr_config).to include("cassette_library_dir = \"spec/cassettes\"")
      expect(vcr_config).to include("hook_into :webmock")
      expect(vcr_config).to include("filter_sensitive_data(\"<API_KEY>\")")

      expect(File.read(File.join(tmp, "spec/rails_helper.rb"))).to include('require "support/vcr"')
    end
  end

  it "installs VCR for Minitest, wiring test_helper.rb" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      FileUtils.mkdir_p(File.join(tmp, "test"))
      File.write(File.join(tmp, "test/test_helper.rb"), "ENV[\"RAILS_ENV\"] ||= \"test\"\nrequire_relative \"../config/environment\"\n")

      ctx = build_context([ "yes" ], app_path: tmp, test_framework: :minitest)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:vcr)).to eq({ vcr: true })

      vcr_config = File.read(File.join(tmp, "test/support/vcr.rb"))
      expect(vcr_config).to include("cassette_library_dir = \"test/cassettes\"")
      expect(vcr_config).to include("filter_sensitive_data(\"<API_KEY>\")")

      expect(File.read(File.join(tmp, "test/test_helper.rb"))).to include('require_relative "support/vcr"')
    end
  end

  it "does not gitignore the cassette directory" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      File.write(File.join(tmp, ".gitignore"), "/log\n")

      ctx = build_context([ "yes" ], app_path: tmp, test_framework: :rspec)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(File.read(File.join(tmp, ".gitignore"))).not_to include("cassette")
    end
  end
end
