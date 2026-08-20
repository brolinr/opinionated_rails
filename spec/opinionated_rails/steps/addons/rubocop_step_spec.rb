# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::RubocopStep do
  def build_context(answers, app_path: Dir.mktmpdir)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
  end

  def write_default_gemfile(tmp)
    File.write(File.join(tmp, "Gemfile"), <<~RUBY)
      source "https://rubygems.org"

      group :development, :test do
        gem "debug", platforms: %i[ mri windows ]
        gem "rubocop-rails-omakase", require: false
      end
    RUBY
  end

  def write_default_rubocop_yml(tmp)
    File.write(File.join(tmp, ".rubocop.yml"), <<~YAML)
      # Omakase Ruby styling for Rails
      inherit_gem: { rubocop-rails-omakase: rubocop.yml }

      # Overwrite or add rules to create your own house style
      #
      # # Use `[a, [b, c]]` not `[ a, [ b, c ] ]`
      # Layout/SpaceInsideArrayLiteralBrackets:
      #   Enabled: false
    YAML
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:rubocop)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([])
    expect(described_class.prompts).to be_a(String)
  end

  it "defaults to Omakase, re-pins the existing gem line, and leaves .rubocop.yml untouched" do
    Dir.mktmpdir do |tmp|
      write_default_gemfile(tmp)
      write_default_rubocop_yml(tmp)

      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:rubocop)).to eq({ rubocop: :omakase })

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include('gem "rubocop-rails-omakase", "1.1.0", require: false')
      expect(gemfile).not_to include('gem "rubocop-rails-omakase", require: false')
      expect(gemfile.scan("rubocop-rails-omakase").size).to eq(1)

      expect(File.read(File.join(tmp, ".rubocop.yml"))).to include("Overwrite or add rules to create your own house style")
    end
  end

  it "does not duplicate the pinned gem line on repeated generate calls" do
    Dir.mktmpdir do |tmp|
      write_default_gemfile(tmp)
      write_default_rubocop_yml(tmp)

      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)
      step.generate(ctx)

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile.scan("rubocop-rails-omakase").size).to eq(1)
    end
  end

  it "creates the group when the default unpinned line is absent" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")
      write_default_rubocop_yml(tmp)

      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to match(/group :development, :test do\n\s+gem "rubocop-rails-omakase", "1\.1\.0", require: false\nend\n/)
    end
  end

  it "writes user overrides below a separator comment for Custom" do
    Dir.mktmpdir do |tmp|
      write_default_gemfile(tmp)
      write_default_rubocop_yml(tmp)

      ctx = build_context([ "2" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:rubocop)).to eq({ rubocop: :custom })

      content = File.read(File.join(tmp, ".rubocop.yml"))
      expect(content).to include("inherit_gem: { rubocop-rails-omakase: rubocop.yml }")
      expect(content).to include("# --- user overrides below ---")
      expect(content).to include(File.read(described_class::CUSTOM_OVERRIDES_TEMPLATE))
    end
  end
end
