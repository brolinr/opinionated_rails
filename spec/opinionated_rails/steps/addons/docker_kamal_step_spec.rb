# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::DockerKamalStep do
  def build_context(answers, app_path: Dir.mktmpdir, skip_bundle_install: true)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers), skip_bundle_install: skip_bundle_install)
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:docker_kamal)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([ :database, :frontend ])
    expect(described_class.prompts).to be_a(String)
  end

  it "is always enabled (Docker itself is never prompted)" do
    expect(described_class.new.if_condition(build_context([]))).to be true
  end

  it "defaults Kamal to off, adds dockerfile-rails, and skips the generator when bundle install is skipped" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n\ngroup :development do\n  gem \"web-console\"\nend\n")

      ctx = build_context([ "" ], app_path: tmp, skip_bundle_install: true)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:docker_kamal)).to eq({ docker: true, kamal: false })

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to match(/group :development do\n\s+gem "web-console"\n\s+gem "dockerfile-rails", "1\.7\.10"\nend\n/)
      expect(gemfile).not_to include("gem \"kamal\"")
      expect(File).not_to exist(File.join(tmp, "Dockerfile"))
    end
  end

  it "creates the development group when absent" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "" ], app_path: tmp)
      described_class.new.generate(ctx)

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to match(/group :development do\n\s+gem "dockerfile-rails", "1\.7\.10"\nend\n/)
    end
  end

  it "adds a pinned top-level kamal gem and outputs kamal: true when enabled" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "yes" ], app_path: tmp, skip_bundle_install: true)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:docker_kamal)).to eq({ docker: true, kamal: true })
      expect(File.read(File.join(tmp, "Gemfile"))).to include('gem "kamal", "2.12.0"')
      expect(File).not_to exist(File.join(tmp, "config/deploy.yml"))
    end
  end

  it "does not duplicate Gemfile entries on repeated generate calls" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "yes" ], app_path: tmp, skip_bundle_install: true)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)
      step.generate(ctx)

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("dockerfile-rails").size).to eq(1)
      expect(gemfile.scan(/gem "kamal"/).size).to eq(1)
    end
  end

  it "rejects invalid choices and keeps asking" do
    ctx = build_context([ "bad", "yes" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:docker_kamal)).to be true
  end
end
