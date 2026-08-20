# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::FactoryOrFixturesStep do
  def build_context(answers, app_path: Dir.mktmpdir, test_framework: :rspec)
    ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
    ctx.set_output(:testing, { test_framework: test_framework })
    ctx
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:factory_or_fixtures)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([ :testing ])
    expect(described_class.prompts).to be_a(String)
  end

  it "is skipped for Minitest" do
    ctx = build_context([], test_framework: :minitest)
    step = described_class.new
    expect(step.if_condition(ctx)).to be false

    step.generate(ctx)

    expect(ctx.output(:factory_or_fixtures)).to be_nil
    expect(File).not_to exist(File.join(ctx.app_path, "spec/factories"))
  end

  it "installs FactoryBot by default, creating a minimal rails_helper.rb when absent" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:factory_or_fixtures)).to eq({ factory_or_fixtures: :factory_bot })
      expect(File.read(File.join(tmp, "Gemfile"))).to match(/group :test do\n\s+gem "factory_bot_rails", "6\.4\.3"\n/)
      expect(Dir.exist?(File.join(tmp, "spec/factories"))).to be true
      expect(File.read(File.join(tmp, "spec/rails_helper.rb"))).to include("FactoryBot::Syntax::Methods")
    end
  end

  it "inserts into an existing group :test block without duplicating gems" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n\ngroup :test do\n  gem \"capybara\"\nend\n")

      ctx = build_context([ "1" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)
      step.generate(ctx)

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("factory_bot_rails").size).to eq(1)
      expect(gemfile).to include("capybara")
    end
  end

  it "does not double-insert config.include on repeated generate calls" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)
      step.generate(ctx)

      content = File.read(File.join(tmp, "spec/rails_helper.rb"))
      expect(content.scan("FactoryBot::Syntax::Methods").size).to eq(1)
    end
  end

  it "chooses Fixtures without writing new files" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "2" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:factory_or_fixtures)).to eq({ factory_or_fixtures: :fixtures })
      expect(File.read(File.join(tmp, "Gemfile"))).not_to include("factory_bot_rails")
      expect(File).not_to exist(File.join(tmp, "spec/factories"))
      expect(File).not_to exist(File.join(tmp, "spec/rails_helper.rb"))
    end
  end
end
