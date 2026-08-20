# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe OpinionatedRails::Steps::Core::TestingStep do
  def build_context(answers, app_path: Dir.mktmpdir, skip_bundle_install: true)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers), skip_bundle_install: skip_bundle_install)
  end

  it "has the expected id, tier, and prompts" do
    expect(described_class.id).to eq(:testing)
    expect(described_class.tier).to eq(:core)
    expect(described_class.prompts).to be_a(String)
  end

  it "defaults to minitest" do
    ctx = build_context([ "" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:testing)).to eq(:minitest)
  end

  it "accepts 'rspec'" do
    ctx = build_context([ "RSpec" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:testing)).to eq(:rspec)
  end

  it "rejects invalid choices and keeps asking" do
    ctx = build_context([ "bad", "1" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:testing)).to eq(:minitest)
  end

  it "generates minitest output" do
    ctx = build_context([ "Minitest" ])
    described_class.new.prompt(ctx)
    described_class.new.generate(ctx)
    expect(ctx.output(:testing)).to eq({ test_framework: :minitest })
  end

  it "appends rspec-rails to Gemfile without running bundle when skipping install" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "")
      ctx = build_context([ "RSpec" ], app_path: tmp, skip_bundle_install: true)
      described_class.new.prompt(ctx)
      described_class.new.generate(ctx)
      expect(File.read(File.join(tmp, "Gemfile"))).to include('gem "rspec-rails"')
      expect(File.read(File.join(tmp, "Gemfile"))).to include("8.0.4")
    end
  end
end
