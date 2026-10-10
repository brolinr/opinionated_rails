# frozen_string_literal: true

require "spec_helper"

# Real `rails new` + install runs (network, minutes each): `RUN_INTEGRATION_SPECS=1 bundle exec rspec`.
# One example per file in spec/fixtures/combos. Every app must boot in each environment, pass its own
# RuboCop, Brakeman, bundler-audit and test suite. Combos whose tools are missing here are skipped, not failed.
RSpec.describe "generated apps (slow)", integration: true do
  def read(app, path) = File.read(File.join(app, path))

  def exist?(app, path) = File.exist?(File.join(app, path))

  # Extra assertions per combo, on top of the shared expect_healthy.
  EXTRA = {
    "default" => lambda { |app|
      expect(read(app, "app/controllers/application_controller.rb")).to include("include Pagy::Method")
      expect(exist?(app, "Dockerfile")).to be true
      expect(exist?(app, "config/deploy.yml")).to be false
    },
    "full_pg_redis" => lambda { |app|
      gemfile = read(app, "Gemfile")
      expect(gemfile).not_to match(/solid_(cache|queue|cable)/)
      expect(gemfile).to match(/group :development, :test do\n\s+gem "rspec-rails"/)
      expect(exist?(app, "config/deploy.yml")).to be true
      expect(exist?(app, "app/services/application_service.rb")).to be true
      expect(YAML.safe_load_file(File.join(app, "config/cable.yml"))).to have_key("staging")

      # Production must not silently fall back to a local Redis...
      no_redis = production_env(app).merge("REDIS_URL" => nil, "RAILS_ENV" => "production", "SECRET_KEY_BASE" => "x")
      missing = run_in(app, "bin/rails", "runner", "1", env: no_redis)
      expect(missing.ok).to be(false)
      expect(missing.output).to include("REDIS_URL is not set")
      # ...except during the Docker asset precompile, which has no Redis.
      expect_command_ok(app, "bin/rails", "runner", "1", env: no_redis.merge("SECRET_KEY_BASE_DUMMY" => "1", "SECRET_KEY_BASE" => nil))
    },
    "api_pg" => lambda { |app|
      expect(exist?(app, "app/models/user.rb")).to be false
      expect(exist?(app, "app/controllers/spa_controller.rb")).to be false
    },
    "rails8_auth" => lambda { |app|
      expect(exist?(app, "app/models/user.rb")).to be true
      expect(exist?(app, "app/models/session.rb")).to be true
    },
    "devise_account" => lambda { |app|
      expect(exist?(app, "app/models/account.rb")).to be true
      expect(Dir.exist?(File.join(app, "app/views/devise"))).to be true
    },
    "custom_everything_off" => lambda { |app|
      expect(exist?(app, ".github/workflows/ci.yml")).to be false
      expect(exist?(app, "spec/factories")).to be false
      expect(read(app, "Gemfile")).not_to include("postmark-rails")
    }
  }.freeze

  Dir.glob(File.join(GeneratedApp::COMBOS, "*.yml")).sort.each do |file|
    combo = File.basename(file, ".yml")

    it "builds a healthy app for #{combo}" do
      answers = combo_answers(combo)
      missing = missing_tools_for(answers)
      skip "missing on this machine: #{missing.join(', ')}" unless missing.empty?

      app = generate_app(combo)

      expect_healthy(app)
      if answers["bundler"]
        expect_command_ok(app, answers["bundler"] == "bun" ? "bun" : "yarn", "run", "build")
        expect_command_ok(app, answers["bundler"] == "bun" ? "bun" : "yarn", "run", "lint:js")
        expect_command_ok(app, answers["bundler"] == "bun" ? "bun" : "yarn", "run", "build:css")
        expect(read(app, "config/routes.rb")).to include('root "spa#root"')
      end
      instance_exec(app, &EXTRA[combo]) if EXTRA[combo]
    end
  end
end
