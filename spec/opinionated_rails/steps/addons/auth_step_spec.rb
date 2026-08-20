# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::AuthStep do
  def build_context(answers, app_path: Dir.mktmpdir, app_type: :full_stack, skip_bundle_install: true)
    ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers), skip_bundle_install: skip_bundle_install)
    ctx.set_output(:app_type, { app_type: app_type })
    ctx
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:auth)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([])
    expect(described_class.prompts).to be_a(String)
  end

  it "defaults to None" do
    ctx = build_context([ "", "" ])
    step = described_class.new
    step.prompt(ctx)
    step.generate(ctx)

    expect(ctx.output(:auth)).to eq({ auth: :none })
  end

  it "captures a custom model name and Rails 8 strategy, always generating as User (no renaming this batch)" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "Account", "2" ], app_path: tmp, skip_bundle_install: true)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.get(:auth_model_name)).to eq("Account")
      expect(ctx.output(:auth)).to eq({ auth: :rails8, user_model: "User" })
    end
  end

  it "passes --api for API-only apps on the Rails 8 branch without actually invoking bundler when skipping install" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "", "rails8" ], app_path: tmp, app_type: :api_only, skip_bundle_install: true)
      step = described_class.new
      step.prompt(ctx)
      expect { step.generate(ctx) }.not_to raise_error
      expect(ctx.output(:auth)).to eq({ auth: :rails8, user_model: "User" })
    end
  end

  it "installs Devise with the pinned gem and the prompted model name" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "Account", "devise" ], app_path: tmp, skip_bundle_install: true)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:auth)).to eq({ auth: :devise, user_model: "Account" })
      expect(File.read(File.join(tmp, "Gemfile"))).to include('gem "devise", "5.0.4"')
    end
  end

  it "does not duplicate the devise gem on repeated generate calls" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "", "3" ], app_path: tmp, skip_bundle_install: true)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)
      step.generate(ctx)

      expect(File.read(File.join(tmp, "Gemfile")).scan("devise").size).to eq(1)
    end
  end

  it "rejects invalid strategy choices and keeps asking" do
    ctx = build_context([ "", "bad", "none" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:auth)).to eq(:none)
  end
end
