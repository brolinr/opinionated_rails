# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::StagingEnvStep do
  def build_context(answers, app_path: Dir.mktmpdir)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:staging_env)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([])
    expect(described_class.prompts).to be_a(String)
  end

  it "is off by default and writes no file" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:staging_env)).to eq({ staging_env: false })
      expect(File).not_to exist(File.join(tmp, "config/environments/staging.rb"))
    end
  end

  it "copies production.rb into staging.rb with a review comment header when enabled" do
    Dir.mktmpdir do |tmp|
      FileUtils.mkdir_p(File.join(tmp, "config/environments"))
      production_content = "Rails.application.configure do\n  config.cache_store = :solid_cache_store\nend\n"
      File.write(File.join(tmp, "config/environments/production.rb"), production_content)

      ctx = build_context([ "yes" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:staging_env)).to eq({ staging_env: true })

      staging_content = File.read(File.join(tmp, "config/environments/staging.rb"))
      expect(staging_content).to include("Review and adjust")
      expect(staging_content).to include(production_content)
    end
  end
end
