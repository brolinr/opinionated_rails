# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::SecretsHandlingStep do
  def build_context(answers, app_path: Dir.mktmpdir)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:secrets_handling)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([])
    expect(described_class.prompts).to be_a(String)
  end

  it "is always prompted" do
    expect(described_class.new.if_condition(build_context([]))).to be true
  end

  it "defaults to Rails credentials with no file changes when master.key and credentials exist" do
    Dir.mktmpdir do |tmp|
      FileUtils.mkdir_p(File.join(tmp, "config"))
      File.write(File.join(tmp, "config/master.key"), "abc123")
      File.write(File.join(tmp, "config/credentials.yml.enc"), "encrypted")
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:secrets_handling)).to eq({ secrets_handling: :rails_credentials })
      expect(File.read(File.join(tmp, "Gemfile"))).not_to include("dotenv")
      expect(File).not_to exist(File.join(tmp, ".env.example"))
    end
  end

  it "warns when master.key or credentials.yml.enc is missing" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.shell.messages).to include(a_string_matching(/master\.key|credentials\.yml\.enc/))
    end
  end

  it "installs dotenv, writes .env.example, and gitignores .env" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      File.write(File.join(tmp, ".gitignore"), "/log\n")

      ctx = build_context([ "2" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:secrets_handling)).to eq({ secrets_handling: :dotenv })
      expect(File.read(File.join(tmp, "Gemfile"))).to match(/group :development, :test do\n\s+gem "dotenv-rails", "3\.2\.0"\nend\n/)
      expect(File).to exist(File.join(tmp, ".env.example"))
      expect(File.read(File.join(tmp, ".gitignore"))).to include(".env")
    end
  end

  it "does not duplicate the Gemfile entry or .gitignore line on repeated generate calls" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      File.write(File.join(tmp, ".gitignore"), "/log\n")

      ctx = build_context([ "dotenv" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)
      step.generate(ctx)

      expect(File.read(File.join(tmp, "Gemfile")).scan("dotenv-rails").size).to eq(1)
      expect(File.read(File.join(tmp, ".gitignore")).scan(".env").size).to eq(1)
    end
  end
  describe ".gitignore handling for dotenv" do
    def gitignore_after(initial)
      Dir.mktmpdir do |tmp|
        File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
        File.write(File.join(tmp, ".gitignore"), initial)
        ctx = OpinionatedRails::Context.new(app_path: tmp, shell: TestShell.new([ "dotenv" ]))
        step = described_class.new
        step.prompt(ctx)
        step.generate(ctx)
        File.read(File.join(tmp, ".gitignore")).lines.map(&:strip)
      end
    end

    it "adds .env when only a comment or a look-alike mentions it" do
      lines = gitignore_after("# keep .env out\n.environment\n")

      expect(lines).to include(".env")
    end

    it "adds .env on its own line when the file has no trailing newline" do
      expect(gitignore_after("/log")).to eq([ "/log", ".env" ])
    end

    it "leaves an existing .env entry alone" do
      expect(gitignore_after("/log\n.env\n")).to eq([ "/log", ".env" ])
    end

    it "keeps .env.example tracked when a glob already ignores every .env file" do
      lines = gitignore_after("/.env*\n")

      expect(lines).to eq([ "/.env*", "!/.env.example" ])
    end

    it "does not re-add the un-ignore line" do
      expect(gitignore_after("/.env*\n!/.env.example\n")).to eq([ "/.env*", "!/.env.example" ])
    end
  end
end
