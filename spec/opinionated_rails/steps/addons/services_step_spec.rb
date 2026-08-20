# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::ServicesStep do
  def build_context(answers, app_path: Dir.mktmpdir)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:services)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([])
    expect(described_class.prompts).to be_a(String)
  end

  it "is off by default and writes no files" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:services)).to eq({ services: false })
      expect(File).not_to exist(File.join(tmp, "app/services/application_service.rb"))
      expect(File).not_to exist(File.join(tmp, "app/services/result.rb"))
    end
  end

  it "writes both service files verbatim when enabled" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "yes" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:services)).to eq({ services: true })

      app_service_path = File.join(tmp, "app/services/application_service.rb")
      result_path = File.join(tmp, "app/services/result.rb")

      expect(File.read(app_service_path)).to eq(
        File.read(File.join(described_class::TEMPLATES_DIR, "application_service.rb"))
      )
      expect(File.read(result_path)).to eq(
        File.read(File.join(described_class::TEMPLATES_DIR, "result.rb"))
      )
      expect(File.read(app_service_path)).to include("# def self.call_async(params: {}, context: {})")
      expect(File.read(app_service_path)).to include("#   AsyncJob.perform_later(name, params, context)")

      expect(File.read(File.join(tmp, "Gemfile"))).to eq("source \"https://rubygems.org\"\n")
    end
  end
end
