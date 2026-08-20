# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::DocsStep do
  def build_context(app_path: Dir.mktmpdir)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new([]))
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:docs)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([])
    expect(described_class.prompts).to be_a(String)
  end

  it "is always enabled" do
    step = described_class.new
    expect(step.if_condition(build_context)).to be true
  end

  it "writes AGENT.md and STYLE.md in the app root" do
    Dir.mktmpdir do |tmp|
      ctx = build_context(app_path: tmp)
      described_class.new.generate(ctx)

      expect(ctx.output(:docs)).to eq({ docs: true })
      expect(File).to exist(File.join(tmp, "AGENT.md"))
      expect(File).to exist(File.join(tmp, "STYLE.md"))
      expect(File.read(File.join(tmp, "AGENT.md"))).to include("Read STYLE.md")
      expect(File.read(File.join(tmp, "STYLE.md"))).to eq(File.read(described_class::STYLE_TEMPLATE))
    end
  end
end
