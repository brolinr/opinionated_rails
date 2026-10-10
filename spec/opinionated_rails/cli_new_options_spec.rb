# frozen_string_literal: true

require "spec_helper"

# Real `rails new --skip-bundle` runs, driven entirely by flags and config files (no prompts).
RSpec.describe "opinionated_rails new options" do
  let(:tmp) { Dir.mktmpdir }
  let(:base) { PromptShell.new }

  before { allow(Thor::Shell::Basic).to receive(:new).and_return(base) }

  after { FileUtils.rm_rf(tmp) }

  def run_new(*args)
    Dir.chdir(tmp) { OpinionatedRails::CLI.start([ "new", *args, "--skip-bundle-install" ]) }
  end

  it "builds an app from --yes alone, taking every default" do
    run_new("plain", "--yes")

    expect(File.read(File.join(tmp, "plain/Gemfile"))).to include('gem "pagy", "43.6.1"')
    expect(base.prompts).to be_empty
  end

  it "takes the database from --database and the bundler from --javascript" do
    run_new("flagged", "--yes", "-d", "postgresql", "-j", "esbuild")

    app = File.join(tmp, "flagged")
    expect(File.read(File.join(app, "Gemfile"))).to match(/gem "pg"/)
    expect(File.read(File.join(app, "package.json"))).to include('"react"')
    expect(base.prompts).to be_empty
  end

  it "accepts Rails-style database names" do
    run_new("sqlapp", "--yes", "--database", "sqlite3")

    expect(File.read(File.join(tmp, "sqlapp/Gemfile"))).to include("sqlite3")
  end

  it "reads answers from a --config file, with flags overriding it" do
    config = File.join(tmp, "answers.yml")
    File.write(config, <<~YAML)
      database: postgresql
      test_framework: rspec
      stack: redis
      staging: true
      services: true
    YAML

    run_new("configured", "--config", config, "--yes", "--database", "sqlite3")

    app = File.join(tmp, "configured")
    gemfile = File.read(File.join(app, "Gemfile"))
    expect(gemfile).to include('gem "rspec-rails"')
    expect(gemfile).to include('gem "sidekiq"')
    expect(gemfile).not_to match(/gem "pg"/)
    expect(File).to exist(File.join(app, "config/environments/staging.rb"))
    expect(File).to exist(File.join(app, "app/services/application_service.rb"))
  end

  it "takes the app name from the config file when no argument is given" do
    config = File.join(tmp, "answers.yml")
    File.write(config, "app_name: from_config\n")

    run_new("--config", config, "--yes")

    expect(Dir.exist?(File.join(tmp, "from_config"))).to be true
  end

  it "warns about config keys that never applied" do
    config = File.join(tmp, "answers.yml")
    File.write(config, "bundler: esbuild\n")

    run_new("ignored", "--config", config, "--yes")

    expect(base.messages.join).to include("Ignored options (their prompt did not apply): bundler")
  end

  it "exits non-zero with a clear message for an invalid value instead of hanging" do
    expect { run_new("bad", "--yes", "--database", "oracle") }
      .to raise_error(SystemExit).and output(/Invalid value "oracle" for `database`/).to_stderr
    expect(Dir.exist?(File.join(tmp, "bad"))).to be false
  end

  it "exits non-zero for an unknown config key" do
    config = File.join(tmp, "answers.yml")
    File.write(config, "databse: postgresql\n")

    expect { run_new("typo", "--config", config, "--yes") }
      .to raise_error(SystemExit).and output(/Unknown option\(s\): databse/).to_stderr
  end

  it "exits non-zero for a missing or malformed config file" do
    expect { run_new("a", "--config", File.join(tmp, "nope.yml")) }
      .to raise_error(SystemExit).and output(/Config file not found/).to_stderr

    bad = File.join(tmp, "bad.yml")
    File.write(bad, "- just\n- a list\n")
    expect { run_new("b", "--config", bad) }
      .to raise_error(SystemExit).and output(/must be a YAML mapping/).to_stderr
  end
  describe "when a step fails after rails new" do
    it "names the step and the partial app, and exits non-zero" do
      allow_any_instance_of(OpinionatedRails::Steps::Addons::FakerStep).to receive(:generate).and_raise("boom")

      expect { run_new("halfway", "--yes") }
        .to raise_error(SystemExit).and output(/Step `faker` failed: boom.*partially generated app is in .*halfway/m).to_stderr
      expect(Dir.exist?(File.join(tmp, "halfway"))).to be true
    end

    it "explains a failed final install the same way" do
      allow_any_instance_of(OpinionatedRails::CLI).to receive(:autocorrect_style).and_raise("rubocop exploded")

      expect { run_new("lastmile", "--yes") }
        .to raise_error(SystemExit).and output(/Step `RuboCop autocorrect` failed: rubocop exploded/).to_stderr
    end
  end
  it "produces no warnings for a normal Redis + mailer + staging run (anchors all matched)" do
    config = File.join(tmp, "answers.yml")
    File.write(config, "stack: redis\nstaging: true\nmailer: true\nauth: devise\n")

    run_new("quiet", "--config", config, "--yes")

    expect(base.messages.grep(/Warning/)).to be_empty
  end
end
