# frozen_string_literal: true

require "open3"
require "tmpdir"

# Helpers for the slow specs: generate a real app through the CLI, then run the app's own tooling.
module GeneratedApp
  Result = Struct.new(:ok, :output)

  # Runs `opinionated_rails new APP_NAME` with real installs, answering prompts by text.
  def generate_app(answers, name: "testapp", dir: Dir.mktmpdir)
    allow(Thor::Shell::Basic).to receive(:new).and_return(PromptShell.new(answers))
    Dir.chdir(dir) { OpinionatedRails::CLI.start([ "new", name ]) }
    File.join(dir, name)
  end

  def run_in(app, *command, env: {})
    output, status = Bundler.with_unbundled_env do
      Open3.capture2e(env, *command, chdir: app)
    end
    Result.new(status.success?, output)
  end

  def expect_command_ok(app, *command, env: {})
    result = run_in(app, *command, env: env)
    expect(result.ok).to be(true), "`#{command.join(' ')}` failed in #{File.basename(app)}:\n#{result.output.lines.last(25).join}"
  end

  # Boots the app in `rails_env` and eager-loads everything, which is what catches bad constants
  # and config (autoloading hides them in development).
  def expect_boots(app, rails_env:, env: {})
    boot_env = { "RAILS_ENV" => rails_env, "SECRET_KEY_BASE_DUMMY" => "1" }.merge(env)
    expect_command_ok(app, "bin/rails", "runner", "Rails.application.eager_load!", env: boot_env)
  end

  def production_env(app)
    database = File.read(File.join(app, "config/database.yml"))
    url = database.include?("postgresql") ? "postgresql://localhost/app" : "sqlite3://#{app}/storage/production.sqlite3"
    { "DATABASE_URL" => url, "REDIS_URL" => "redis://localhost:6379/1" }
  end

  # Everything a freshly generated app should pass before the user touches it.
  def expect_healthy(app)
    expect_command_ok(app, "bundle", "check")
    expect_boots(app, rails_env: "development")
    expect_boots(app, rails_env: "production", env: production_env(app))
    expect_boots(app, rails_env: "staging", env: production_env(app)) if File.exist?(File.join(app, "config/environments/staging.rb"))
    expect_command_ok(app, "bin/rubocop")
    expect_command_ok(app, "bin/brakeman", "-q", "--no-pager")
    expect_command_ok(app, "bin/bundler-audit")
    YAML.safe_load_file(File.join(app, ".github/workflows/ci.yml")) if File.exist?(File.join(app, ".github/workflows/ci.yml"))
  end
end

RSpec.configure { |config| config.include GeneratedApp }
