# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::SolidStackStep do
  def build_context(answers, app_path: Dir.mktmpdir)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
  end

  def write_solid_defaults(tmp)
    FileUtils.mkdir_p(File.join(tmp, "config/environments"))
    File.write(
      File.join(tmp, "config/environments/production.rb"),
      <<~RUBY
        Rails.application.configure do
          config.cache_store = :solid_cache_store
          config.active_job.queue_adapter = :solid_queue
          config.solid_queue.connects_to = { database: { writing: :queue } }
        end
      RUBY
    )
    File.write(
      File.join(tmp, "config/cable.yml"),
      <<~YAML
        development:
          adapter: async

        test:
          adapter: test

        production:
          adapter: solid_cable
          connects_to:
            database:
              writing: cable
          polling_interval: 0.1.seconds
          message_retention: 1.day
      YAML
    )
    File.write(File.join(tmp, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:solid_stack)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([])
    expect(described_class.prompts).to be_a(String)
  end

  it "defaults to Solid and makes no changes" do
    Dir.mktmpdir do |tmp|
      write_solid_defaults(tmp)
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:solid_stack)).to eq({ solid_stack: :solid })
      expect(File.read(File.join(tmp, "Gemfile"))).not_to include("redis")
      expect(File.read(File.join(tmp, "config/environments/production.rb"))).to include(":solid_cache_store")
      expect(File.read(File.join(tmp, "config/cable.yml"))).to include("adapter: solid_cable")
    end
  end

  it "swaps to Redis + Sidekiq when chosen" do
    Dir.mktmpdir do |tmp|
      write_solid_defaults(tmp)
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "2" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:solid_stack)).to eq({ solid_stack: :redis })

      gemfile = File.read(File.join(tmp, "Gemfile"))
      expect(gemfile).to include('gem "redis", "6.0.0"')
      expect(gemfile).to include('gem "sidekiq", "8.1.7"')

      prod_config = File.read(File.join(tmp, "config/environments/production.rb"))
      expect(prod_config).to include("config.cache_store = :redis_cache_store")
      expect(prod_config).not_to include(":solid_cache_store")
      expect(prod_config).to include("config.active_job.queue_adapter = :sidekiq")
      expect(prod_config).not_to include("solid_queue")

      cable_config = File.read(File.join(tmp, "config/cable.yml"))
      expect(cable_config).to include("adapter: redis")
      expect(cable_config).not_to include("solid_cable")

      expect(File).to exist(File.join(tmp, "config/initializers/sidekiq.rb"))
      expect(File.read(File.join(tmp, "config/initializers/sidekiq.rb"))).to include("Sidekiq.configure_server")

      routes = File.read(File.join(tmp, "config/routes.rb"))
      expect(routes).to include("# mount Sidekiq::Web")
      expect(routes).not_to match(/^\s*mount Sidekiq::Web/)
    end
  end

  it "does not duplicate gems or route comments on repeated generate calls" do
    Dir.mktmpdir do |tmp|
      write_solid_defaults(tmp)
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "redis" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)
      step.generate(ctx)

      expect(File.read(File.join(tmp, "Gemfile")).scan('gem "redis"').size).to eq(1)
      expect(File.read(File.join(tmp, "config/routes.rb")).scan("mount Sidekiq::Web").size).to eq(1)
    end
  end
end
