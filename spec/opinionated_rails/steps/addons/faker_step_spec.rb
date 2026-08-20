# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::FakerStep do
  def build_context(app_path: Dir.mktmpdir)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new([]))
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:faker)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([])
    expect(described_class.prompts).to be_a(String)
  end

  it "is always enabled with no prompt" do
    ctx = build_context
    step = described_class.new
    expect(step.if_condition(ctx)).to be true
  end

  it "inserts faker into the existing group :development, :test block" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n\ngroup :development, :test do\n  gem \"debug\"\nend\n")

      ctx = build_context(app_path: tmp)
      described_class.new.generate(ctx)

      expect(ctx.output(:faker)).to eq({ faker: true })
      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to match(/group :development, :test do\n\s+gem "debug"\n\s+gem "faker", "3\.8\.0"\nend\n/)
    end
  end

  it "creates the group when absent" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context(app_path: tmp)
      described_class.new.generate(ctx)

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to match(/group :development, :test do\n\s+gem "faker", "3\.8\.0"\nend\n/)
    end
  end

  it "does not duplicate on repeated generate calls" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context(app_path: tmp)
      step = described_class.new
      step.generate(ctx)
      step.generate(ctx)

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("faker").size).to eq(1)
    end
  end
end
