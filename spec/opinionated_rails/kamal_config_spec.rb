# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::KamalConfig do
  def config(database: :sqlite3, stack: :solid, app_name: "my_app")
    YAML.safe_load(described_class.deploy_yml(app_name: app_name, database: database, stack: stack))
  end

  it "names the service after the app, with dashes" do
    expect(config["service"]).to eq("my-app")
    expect(config["image"]).to eq("CHANGE_ME_registry_username/my-app")
  end

  it "leaves only CHANGE_ME placeholders for the values it cannot know" do
    text = described_class.deploy_yml(app_name: "my_app", database: :sqlite3, stack: :solid)
    values = text.lines.reject { |line| line.start_with?("#") }.join

    expect(values.scan(/CHANGE_ME\w*/).uniq).to contain_exactly("CHANGE_ME_registry_username", "CHANGE_ME_server_ip", "CHANGE_ME")
  end

  it "passes the Rails master key and reads the registry password from secrets" do
    c = config

    expect(c.dig("env", "secret")).to include("RAILS_MASTER_KEY")
    expect(c.dig("registry", "password")).to eq([ "KAMAL_REGISTRY_PASSWORD" ])
  end

  describe "SQLite" do
    it "persists the database and uploads, which a deploy would otherwise wipe" do
      expect(config["volumes"]).to contain_exactly("my_app_storage:/rails/storage", "my_app_data:/data")
    end

    it "does not ask for a DATABASE_URL secret" do
      expect(config.dig("env", "secret")).not_to include("DATABASE_URL")
    end
  end

  %i[ postgresql mysql2 ].each do |database|
    describe database.to_s do
      it "takes DATABASE_URL as a secret and keeps only uploads on a volume" do
        c = config(database: database)

        expect(c.dig("env", "secret")).to include("DATABASE_URL")
        expect(c["volumes"]).to eq([ "my_app_storage:/rails/storage" ])
      end
    end
  end

  describe "Solid stack" do
    it "runs jobs inside Puma and has no job role or accessories" do
      c = config

      expect(c.dig("env", "clear")).to eq({ "SOLID_QUEUE_IN_PUMA" => true })
      expect(c["servers"].keys).to eq([ "web" ])
      expect(c).not_to have_key("accessories")
    end
  end

  describe "Redis + Sidekiq stack" do
    it "adds a Sidekiq job role, a Redis accessory and a REDIS_URL pointing at it" do
      c = config(stack: :redis)

      expect(c.dig("servers", "job", "cmd")).to eq("bundle exec sidekiq")
      expect(c.dig("accessories", "redis", "image")).to eq("redis:7")
      expect(c.dig("env", "clear", "REDIS_URL")).to eq("redis://my-app-redis:6379/1")
      expect(c.dig("env", "clear")).not_to have_key("SOLID_QUEUE_IN_PUMA")
    end
  end

  describe ".secrets" do
    it "reads values from the environment or master.key and never embeds one" do
      text = described_class.secrets(database: :postgresql)

      expect(text).to include("RAILS_MASTER_KEY=$(cat config/master.key)", "KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD", "DATABASE_URL=$DATABASE_URL")
    end

    it "omits DATABASE_URL for SQLite" do
      expect(described_class.secrets(database: :sqlite3)).not_to include("DATABASE_URL")
    end
  end
end
