# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::DockerKamalStep do
  def build_context(answers, app_path: Dir.mktmpdir, skip_bundle_install: true)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers), skip_bundle_install: skip_bundle_install)
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:docker_kamal)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([ :database, :frontend, :solid_stack ])
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
  describe "deploy files after kamal init" do
    def run_with_stubbed_commands(tmp, database:, stack:)
      FileUtils.mkdir_p(File.join(tmp, "config"))
      FileUtils.mkdir_p(File.join(tmp, ".kamal"))
      File.write(File.join(tmp, "config/deploy.yml"), "# kamal init template\n")
      File.write(File.join(tmp, ".kamal/secrets"), "# kamal init template\n")
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = OpinionatedRails::Context.new(app_path: tmp, shell: TestShell.new([ "yes" ]), skip_bundle_install: false)
      ctx.set_output(:app_name, { app_name: "shop_app" })
      ctx.set_output(:database, { database: database })
      ctx.set_output(:solid_stack, { solid_stack: stack })
      step = described_class.new
      allow(step).to receive(:run_in_app).and_return(true)
      step.prompt(ctx)
      step.generate(ctx)
    end

    it "replaces the commented-out templates with a config for the chosen stack" do
      Dir.mktmpdir do |tmp|
        run_with_stubbed_commands(tmp, database: :postgresql, stack: :redis)

        deploy = YAML.safe_load_file(File.join(tmp, "config/deploy.yml"))
        expect(deploy["service"]).to eq("shop-app")
        expect(deploy.dig("servers", "job", "cmd")).to eq("bundle exec sidekiq")
        expect(File.read(File.join(tmp, ".kamal/secrets"))).to include("DATABASE_URL=$DATABASE_URL")
      end
    end

    it "persists SQLite data" do
      Dir.mktmpdir do |tmp|
        run_with_stubbed_commands(tmp, database: :sqlite3, stack: :solid)

        expect(YAML.safe_load_file(File.join(tmp, "config/deploy.yml"))["volumes"]).to include("shop_app_data:/data")
      end
    end
  end
end
