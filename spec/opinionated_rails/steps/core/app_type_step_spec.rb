# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Core::AppTypeStep do
  def build_context(answers)
    OpinionatedRails::Context.new(app_path: "/tmp", shell: TestShell.new(answers))
  end

  it "has the expected id, tier, and prompts" do
    expect(described_class.id).to eq(:app_type)
    expect(described_class.tier).to eq(:core)
    expect(described_class.prompts).to be_a(String)
  end

  it "defaults to full_stack" do
    ctx = build_context([ "" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:app_type)).to eq(:full_stack)
  end

  it "accepts 'api-only'" do
    ctx = build_context([ "API-only" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:app_type)).to eq(:api_only)
  end

  it "accepts '2'" do
    ctx = build_context([ "2" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:app_type)).to eq(:api_only)
  end

  it "rejects invalid choices and keeps asking" do
    ctx = build_context([ "bad", "1" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:app_type)).to eq(:full_stack)
    expect(ctx.shell.messages.last).to match(/Invalid/)
  end

  it "generates the expected output" do
    ctx = build_context([ "2" ])
    described_class.new.prompt(ctx)
    described_class.new.generate(ctx)
    expect(ctx.output(:app_type)).to eq({ app_type: :api_only })
  end
end
