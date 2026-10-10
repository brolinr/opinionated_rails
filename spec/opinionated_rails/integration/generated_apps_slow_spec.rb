# frozen_string_literal: true

require "spec_helper"

# Real `rails new` + `bundle install` runs (network, several minutes): `RUN_INTEGRATION_SPECS=1 bundle exec rspec`.
# Each app must boot in every environment and pass its own RuboCop, Brakeman and bundler-audit.
RSpec.describe "generated apps (slow)", integration: true do
  it "builds a healthy app from all the defaults" do
    app = generate_app({})

    expect_healthy(app)
    expect(File.read(File.join(app, "app/controllers/application_controller.rb"))).to include("include Pagy::Method")
    expect(File).to exist(File.join(app, "Dockerfile"))
    expect(File).not_to exist(File.join(app, "config/deploy.yml"))
  end

  it "builds a healthy app with PostgreSQL, Redis + Sidekiq, RSpec, Devise, staging, services, dotenv, VCR and Kamal" do
    app = generate_app({
      "Database" => "postgresql", "Test framework" => "RSpec", "Stack" => "redis", "Staging" => "yes",
      "application service" => "yes", "Secrets" => "dotenv", "Authentication" => "devise", "VCR" => "yes", "Kamal" => "yes"
    })

    expect_healthy(app)
    gemfile = File.read(File.join(app, "Gemfile"))
    expect(gemfile).not_to match(/solid_(cache|queue|cable)/)
    expect(gemfile).to match(/group :development, :test do\n\s+gem "rspec-rails"/)
    expect(File).to exist(File.join(app, "config/deploy.yml"))
    expect(File).to exist(File.join(app, "app/services/application_service.rb"))
    expect(YAML.safe_load_file(File.join(app, "config/cable.yml"))).to have_key("staging")
  end

  it "builds a healthy API-only app and skips authentication it cannot support" do
    app = generate_app({ "App type" => "API-only", "Database" => "postgresql", "Staging" => "yes", "Authentication" => "rails8" })

    expect_healthy(app)
    expect(File).not_to exist(File.join(app, "app/models/user.rb"))
    expect(File).not_to exist(File.join(app, "app/controllers/spa_controller.rb"))
  end

  it "builds a working Rails 8 authentication setup" do
    app = generate_app({ "Authentication" => "rails8" })

    expect_healthy(app)
    expect(File).to exist(File.join(app, "app/models/user.rb"))
    expect(File).to exist(File.join(app, "app/models/session.rb"))
  end

  it "uses a custom Devise model name and generates its views" do
    app = generate_app({ "User model name" => "Account", "Authentication" => "devise" })

    expect_healthy(app)
    expect(File).to exist(File.join(app, "app/models/account.rb"))
    expect(Dir.exist?(File.join(app, "app/views/devise"))).to be true
  end

  context "with a React frontend" do
    before do
      skip "yarn is not installed" unless OpinionatedRails::Prerequisites.available?("yarn")
    end

    it "builds, lints and bundles its JavaScript and CSS" do
      app = generate_app({ "Frontend" => "react", "Test framework" => "RSpec", "Authentication" => "rails8" })

      expect_healthy(app)
      expect_command_ok(app, "yarn", "build")
      expect_command_ok(app, "yarn", "lint:js")
      expect_command_ok(app, "yarn", "build:css")
      expect(File.read(File.join(app, "config/routes.rb"))).to include('root "spa#root"')
    end
  end
end
