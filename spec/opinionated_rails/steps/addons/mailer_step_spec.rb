# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::MailerStep do
  def build_context(answers, app_path: Dir.mktmpdir, secrets_handling: :rails_credentials)
    ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
    ctx.set_output(:secrets_handling, { secrets_handling: secrets_handling })
    ctx
  end

  def write_environment_files(tmp)
    FileUtils.mkdir_p(File.join(tmp, "config/environments"))
    File.write(
      File.join(tmp, "config/environments/development.rb"),
      "Rails.application.configure do\n  config.action_mailer.raise_delivery_errors = false\n  config.action_mailer.default_url_options = { host: \"localhost\", port: 3000 }\nend\n"
    )
    File.write(
      File.join(tmp, "config/environments/production.rb"),
      "Rails.application.configure do\n  config.action_mailer.default_url_options = { host: \"example.com\" }\nend\n"
    )
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:mailer)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([ :secrets_handling ])
    expect(described_class.prompts).to be_a(String)
  end

  it "is on by default" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      write_environment_files(tmp)

      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:mailer)).to eq({ mailer: true })
    end
  end

  it "leaves the Gemfile and config untouched when disabled" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      write_environment_files(tmp)

      ctx = build_context([ "no" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:mailer)).to eq({ mailer: false })
      expect(File.read(File.join(tmp, "Gemfile"))).not_to include("letter_opener")
      expect(File.read(File.join(tmp, "config/environments/development.rb"))).not_to include("letter_opener")
    end
  end

  it "adds pinned gems and wires delivery methods into both environments" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      write_environment_files(tmp)

      ctx = build_context([ "yes" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to match(/group :development do\n\s+gem "letter_opener", "1\.10\.0"\nend\n/)
      expect(gemfile).to include('gem "postmark-rails", "0.22.1"')

      dev_config = File.read(File.join(tmp, "config/environments/development.rb"))
      expect(dev_config).to include("config.action_mailer.delivery_method = :letter_opener")

      prod_config = File.read(File.join(tmp, "config/environments/production.rb"))
      expect(prod_config).to include("config.action_mailer.delivery_method = :postmark")
      expect(prod_config).to include("Rails.application.credentials.dig(:postmark, :api_token)")
    end
  end

  it "does not duplicate config lines on repeated generate calls" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      write_environment_files(tmp)

      ctx = build_context([ "yes" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)
      step.generate(ctx)

      dev_config = File.read(File.join(tmp, "config/environments/development.rb"))
      expect(dev_config.scan("delivery_method = :letter_opener").size).to eq(1)

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("letter_opener").size).to eq(1)
    end
  end

  it "uses ENV and appends to .env.example when secrets_handling is dotenv" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      write_environment_files(tmp)
      File.write(File.join(tmp, ".env.example"), "# placeholders\n")

      ctx = build_context([ "yes" ], app_path: tmp, secrets_handling: :dotenv)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      prod_config = File.read(File.join(tmp, "config/environments/production.rb"))
      expect(prod_config).to include('ENV["POSTMARK_API_TOKEN"]')
      expect(prod_config).not_to include("Rails.application.credentials")

      expect(File.read(File.join(tmp, ".env.example"))).to include("POSTMARK_API_TOKEN=")
    end
  end

  it "does not duplicate the .env.example placeholder on repeated generate calls" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      write_environment_files(tmp)
      File.write(File.join(tmp, ".env.example"), "# placeholders\n")

      ctx = build_context([ "yes" ], app_path: tmp, secrets_handling: :dotenv)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)
      step.generate(ctx)

      expect(File.read(File.join(tmp, ".env.example")).scan("POSTMARK_API_TOKEN=").size).to eq(1)
    end
  end

  it "does not overwrite an existing ApplicationMailer" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      write_environment_files(tmp)

      mailer_dir = File.join(tmp, "app/mailers")
      FileUtils.mkdir_p(mailer_dir)
      existing = "class ApplicationMailer < ActionMailer::Base\n  default from: \"custom@example.com\"\nend\n"
      File.write(File.join(mailer_dir, "application_mailer.rb"), existing)

      ctx = build_context([ "yes" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(File.read(File.join(mailer_dir, "application_mailer.rb"))).to eq(existing)
    end
  end
  describe "when an expected Rails line is missing" do
    it "warns with the lines to add instead of silently leaving mail unconfigured" do
      Dir.mktmpdir do |tmp|
        FileUtils.mkdir_p(File.join(tmp, "config/environments"))
        File.write(File.join(tmp, "config/environments/production.rb"), "Rails.application.configure do\nend\n")
        File.write(File.join(tmp, "config/environments/development.rb"), "Rails.application.configure do\nend\n")
        File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
        shell = TestShell.new([ "" ])
        ctx = OpinionatedRails::Context.new(app_path: tmp, shell: shell)
        step = described_class.new
        step.prompt(ctx)
        step.generate(ctx)

        warning = shell.messages.grep(/Warning/).join("\n")
        expect(warning).to include("config/environments/production.rb", "config.action_mailer.delivery_method = :postmark")
        expect(warning).to include("config/environments/development.rb")
      end
    end

    it "warns when an environment file is missing" do
      Dir.mktmpdir do |tmp|
        File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
        shell = TestShell.new([ "" ])
        ctx = OpinionatedRails::Context.new(app_path: tmp, shell: shell)
        step = described_class.new
        step.prompt(ctx)
        step.generate(ctx)

        expect(shell.messages.grep(/not found; mailer settings were not added/).size).to eq(2)
      end
    end
  end
end
