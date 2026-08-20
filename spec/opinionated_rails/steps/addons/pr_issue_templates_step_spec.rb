# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::PrIssueTemplatesStep do
  def build_context(app_path: Dir.mktmpdir)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new([]))
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:pr_issue_templates)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([])
    expect(described_class.prompts).to be_a(String)
  end

  it "is always enabled with no prompt" do
    expect(described_class.new.if_condition(build_context)).to be true
  end

  it "writes the pull request and issue templates verbatim" do
    Dir.mktmpdir do |tmp|
      ctx = build_context(app_path: tmp)
      described_class.new.generate(ctx)

      expect(ctx.output(:pr_issue_templates)).to eq({ pr_issue_templates: true })

      pr_path = File.join(tmp, ".github/PULL_REQUEST_TEMPLATE.md")
      bug_path = File.join(tmp, ".github/ISSUE_TEMPLATE/bug_report.md")
      feature_path = File.join(tmp, ".github/ISSUE_TEMPLATE/feature_request.md")

      expect(File).to exist(pr_path)
      expect(File).to exist(bug_path)
      expect(File).to exist(feature_path)

      expect(File.read(pr_path)).to eq(
        File.read(File.join(described_class::TEMPLATES_DIR, "PULL_REQUEST_TEMPLATE.md"))
      )
      expect(File.read(bug_path)).to eq(
        File.read(File.join(described_class::TEMPLATES_DIR, "ISSUE_TEMPLATE/bug_report.md"))
      )
      expect(File.read(feature_path)).to eq(
        File.read(File.join(described_class::TEMPLATES_DIR, "ISSUE_TEMPLATE/feature_request.md"))
      )
    end
  end
end
