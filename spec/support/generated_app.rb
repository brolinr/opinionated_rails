# frozen_string_literal: true

require "open3"
require "tmpdir"

# Helpers for the slow specs: generate a real app through the CLI, then run the app's own tooling.
module GeneratedApp
  Result = Struct.new(:ok, :output)

  COMBOS = File.expand_path("../fixtures/combos", __dir__)

  # Runs `opinionated_rails new APP_NAME --config FILE --yes` with real installs. `answers` is a
  # hash, or the name of a file in spec/fixtures/combos.
  def generate_app(answers, name: "testapp", dir: Dir.mktmpdir)
    config = File.join(dir, "answers.yml")
    if answers.is_a?(String)
      FileUtils.cp(File.join(COMBOS, "#{answers}.yml"), config)
    else
      File.write(config, answers.to_yaml)
    end

    allow(Thor::Shell::Basic).to receive(:new).and_return(PromptShell.new)
    Dir.chdir(dir) { OpinionatedRails::CLI.start([ "new", name, "--config", config, "--yes" ]) }
    File.join(dir, name)
  end

  def combo_answers(combo)
    YAML.safe_load_file(File.join(COMBOS, "#{combo}.yml")) || {}
  end

  # Tools a combo needs on this machine; the slow spec skips (not fails) when they are missing.
  def missing_tools_for(answers)
    tools = []
    tools.concat(answers["bundler"].to_s == "bun" ? %w[ bun ] : %w[ node yarn ]) if answers["bundler"]
    tools << "mysqladmin" if answers["database"].to_s == "mysql"
    tools.reject { |tool| OpinionatedRails::Prerequisites.available?(tool) }
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

  # A database the app's tests can use, or nil when none is reachable here (then tests are skipped).
  def test_database_env(app)
    name = "otr_#{File.basename(File.dirname(app))}".gsub(/\W/, "_").downcase
    adapter = File.read(File.join(app, "config/database.yml"))

    if adapter.include?("postgresql")
      return unless system("pg_isready", out: File::NULL, err: File::NULL)

      { "DATABASE_URL" => "postgres://#{ENV.fetch('USER', 'postgres')}@localhost:5432/#{name}_test" }
    elsif adapter.include?("mysql")
      return unless system("mysqladmin", "-uroot", "-h127.0.0.1", "ping", out: File::NULL, err: File::NULL)

      { "DATABASE_URL" => "mysql2://root@127.0.0.1:3306/#{name}_test" }
    else
      {}
    end
  end

  RACK_SMOKE = <<~RUBY
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host! "localhost"
    session.get "/up"
    abort "GET /up returned \#{session.response.status}" unless session.response.status == 200
    unless Rails.application.config.api_only
      session.get "/"
      # No root route is a legitimate 404 (as in any new Rails app); a server error is not.
      abort "GET / returned \#{session.response.status}" unless session.response.status < 500
    end
  RUBY

  # Runs the generated CI workflow's own test job against a fresh checkout (build output removed), so a
  # wrong CI file fails here, then hits /up and / through Rack. Without a workflow it runs the equivalent by hand.
  def expect_app_tests_pass(app)
    db_env = test_database_env(app)
    return unless db_env

    env = db_env.merge("RAILS_ENV" => "test")
    FileUtils.rm_rf(Dir.glob(File.join(app, "app/assets/builds/*")))

    workflow = File.join(app, ".github/workflows/ci.yml")
    if File.exist?(workflow)
      job = YAML.safe_load_file(workflow).dig("jobs", "test")
      ci_env = (job["env"] || {}).merge(env)
      job["steps"].filter_map { |step| step["run"] }.reject { |cmd| cmd.include?("apt-get") }.each do |command|
        expect_command_ok(app, "sh", "-c", command, env: ci_env)
      end
      expect_command_ok(app, "bin/rails", "runner", RACK_SMOKE, env: env)
    else
      expect_command_ok(app, "bin/rails", "db:create", "db:migrate", "db:test:prepare", env: env)
      expect_command_ok(app, "bin/rails", "runner", RACK_SMOKE, env: env)
      expect_command_ok(app, *(Dir.exist?(File.join(app, "spec")) ? %w[ bundle exec rspec ] : %w[ bin/rails test ]), env: env)
    end
  ensure
    run_in(app, "bin/rails", "db:drop", env: env.merge("DISABLE_DATABASE_ENVIRONMENT_CHECK" => "1")) if env && !db_env.empty?
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
    # `kamal config` parses and validates deploy.yml offline (secrets are read from the environment).
    if File.exist?(File.join(app, "config/deploy.yml"))
      expect_command_ok(app, "bundle", "exec", "kamal", "config", env: { "KAMAL_REGISTRY_PASSWORD" => "x", "DATABASE_URL" => "x" })
    end
    YAML.safe_load_file(File.join(app, ".github/workflows/ci.yml")) if File.exist?(File.join(app, ".github/workflows/ci.yml"))
    expect_app_tests_pass(app)
  end
end

RSpec.configure { |config| config.include GeneratedApp }
