# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class SolidStackStep < Step
        def self.id = :solid_stack
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Configure Solid Trifecta"
        def self.description = "Sets up Solid Queue, Solid Cache, and Solid Cable for background jobs, caching, and Action Cable."
        def self.prompts = "Background jobs/cache/cable: Solid Trifecta or Redis+Sidekiq (default: Solid)"

        REDIS_VERSION = "6.0.0".freeze
        SIDEKIQ_VERSION = "8.1.7".freeze

        # `config.cache_store`/`config.active_job.queue_adapter` only get rewritten to their
        # Solid variants by `solid_cache:install`/`solid_queue:install`, which are `after_bundle`
        # hooks that never run under `rails new --skip-bundle` (our fast/no-network test path).
        # So both the "Solid already installed" anchor and the untouched Rails default (still
        # commented out) are handled here.
        CACHE_STORE_ANCHORS = [
          "config.cache_store = :solid_cache_store",
          "# config.cache_store = :mem_cache_store"
        ].freeze
        CACHE_STORE_REPLACEMENT = "config.cache_store = :redis_cache_store, " \
                                  "{ url: ENV.fetch(\"REDIS_URL\", \"redis://localhost:6379/1\") }"

        QUEUE_ADAPTER_ANCHORS = [
          "  config.active_job.queue_adapter = :solid_queue\n  config.solid_queue.connects_to = { database: { writing: :queue } }\n",
          "  # config.active_job.queue_adapter = :resque\n"
        ].freeze
        QUEUE_ADAPTER_REPLACEMENT = "  config.active_job.queue_adapter = :sidekiq\n"

        # Likewise, `config/cable.yml`'s production block only becomes `adapter: solid_cable`
        # once `solid_cable:install` (also `after_bundle`) has run; otherwise it's still Rails'
        # own un-swapped default, which already reads `adapter: redis` — nothing to do there.
        CABLE_PRODUCTION_BLOCK = <<~YAML
          production:
            adapter: solid_cable
            connects_to:
              database:
                writing: cable
            polling_interval: 0.1.seconds
            message_retention: 1.day
        YAML

        CABLE_PRODUCTION_REPLACEMENT = <<~YAML
          production:
            adapter: redis
            url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
        YAML

        SIDEKIQ_INITIALIZER = <<~RUBY
          # frozen_string_literal: true

          # Production must be told where Redis is, or jobs and cable silently talk to nothing. The Docker
          # build runs assets:precompile with SECRET_KEY_BASE_DUMMY and no Redis, so that case is exempt.
          redis_url = ENV.fetch("REDIS_URL") do
            raise "REDIS_URL is not set" if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].to_s.empty?

            "redis://localhost:6379/1"
          end

          Sidekiq.configure_server do |config|
            config.redis = { url: redis_url }
          end

          Sidekiq.configure_client do |config|
            config.redis = { url: redis_url }
          end
        RUBY

        SIDEKIQ_WEB_ROUTE_COMMENT = "  # Gate this behind authentication before enabling — Sidekiq::Web has no built-in auth.\n" \
                                     "  # mount Sidekiq::Web => \"/sidekiq\"\n"

        SOLID_GEMS = %w[ solid_cache solid_queue solid_cable ].freeze
        SOLID_FILES = %w[
          config/cache.yml config/queue.yml config/recurring.yml
          db/cache_schema.rb db/queue_schema.rb db/cable_schema.rb
          bin/jobs
        ].freeze
        SOLID_DATABASE_KEYS = %w[ cache queue cable ].freeze

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          shell.say("Choose a background jobs/cache/cable stack:")
          shell.say("  1. Solid Trifecta (default)")
          shell.say("  2. Redis + Sidekiq")

          choice = shell.ask("Stack (default: Solid):").to_s.strip
          choice = "1" if choice.empty?

          loop do
            case choice.downcase
            when "solid", "1"
              context.answer(:solid_stack, :solid)
              break
            when "redis", "2"
              context.answer(:solid_stack, :redis)
              break
            else
              shell.say("Invalid. Enter 'Solid', 'Redis', 1, or 2.", :red)
              choice = shell.ask("Stack (default: Solid):").to_s.strip
              choice = "1" if choice.empty?
            end
          end
        end

        def generate(context)
          strategy = context.get(:solid_stack) || :solid

          install_redis_and_sidekiq(context) if strategy == :redis

          context.set_output(:solid_stack, { solid_stack: strategy })
        end

        def outputs(context)
          context.output(:solid_stack)
        end

        private

        def install_redis_and_sidekiq(context)
          add_top_level_gem(context, "gem \"redis\", \"#{REDIS_VERSION}\"")
          add_top_level_gem(context, "gem \"sidekiq\", \"#{SIDEKIQ_VERSION}\"")

          swap_cache_store(context)
          swap_queue_adapter(context)
          swap_cable_adapter(context)
          write_sidekiq_initializer(context)
          add_commented_sidekiq_route(context)
          remove_solid_leftovers(context)
        end

        # The Redis stack replaces Solid entirely; leaving the gems, configs and database
        # blocks behind makes other environments (e.g. staging) boot solid_cable without config.
        def remove_solid_leftovers(context)
          remove_solid_gems(context)
          SOLID_FILES.each { |file| FileUtils.rm_f(File.join(context.app_path, file)) }
          remove_solid_database_blocks(context)
        end

        def remove_solid_gems(context)
          path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(path)

          pattern = /\Agem\s+["'](?:#{SOLID_GEMS.join('|')})["']/
          File.write(path, File.read(path).lines.reject { |line| line.match?(pattern) }.join)
        end

        def remove_solid_database_blocks(context)
          path = File.join(context.app_path, "config/database.yml")
          return unless File.exist?(path)

          keys = SOLID_DATABASE_KEYS.join("|")
          content = File.read(path).gsub(/^  (?:#{keys}):\n(?:    .*\n|\s*\n)*?(?=  \S|\S|\z)/, "")
          File.write(path, content)
        end

        def swap_cache_store(context)
          swap_first_matching_anchor(
            context,
            File.join(context.app_path, "config/environments/production.rb"),
            CACHE_STORE_ANCHORS,
            CACHE_STORE_REPLACEMENT
          )
        end

        def swap_queue_adapter(context)
          swap_first_matching_anchor(
            context,
            File.join(context.app_path, "config/environments/production.rb"),
            QUEUE_ADAPTER_ANCHORS,
            QUEUE_ADAPTER_REPLACEMENT
          )
        end

        # If Rails rewords the text we match, the swap would silently do nothing and leave the app on
        # Solid while the Gemfile says Redis; say so instead.
        def swap_first_matching_anchor(context, path, anchors, replacement)
          relative = path.delete_prefix("#{context.app_path}/")
          return warn_not_swapped(context, relative, replacement) unless File.exist?(path)

          content = File.read(path)
          return if content.include?(replacement)

          anchor = anchors.find { |candidate| content.include?(candidate) }
          return warn_not_swapped(context, relative, replacement) unless anchor

          File.write(path, content.sub(anchor, replacement))
        end

        def warn_not_swapped(context, relative, replacement)
          context.shell.say(
            "Warning: could not switch #{relative} to Redis (expected Rails text not found). Set it by hand: #{replacement.strip}",
            :yellow
          )
        end

        def swap_cable_adapter(context)
          path = File.join(context.app_path, "config/cable.yml")
          return unless File.exist?(path)

          content = File.read(path)
          # Un-swapped Rails defaults (e.g. --skip-bundle) already read `adapter: redis`.
          unless content.include?(CABLE_PRODUCTION_BLOCK)
            unless content.include?("adapter: redis")
              context.shell.say("Warning: config/cable.yml has no Solid Cable or Redis production block; set `adapter: redis` by hand.", :yellow)
            end
            return
          end

          File.write(path, content.sub(CABLE_PRODUCTION_BLOCK, CABLE_PRODUCTION_REPLACEMENT))
        end

        def write_sidekiq_initializer(context)
          path = File.join(context.app_path, "config/initializers/sidekiq.rb")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, SIDEKIQ_INITIALIZER)
        end

        def add_commented_sidekiq_route(context)
          path = File.join(context.app_path, "config/routes.rb")
          return unless File.exist?(path)

          content = File.read(path)
          return if content.include?("mount Sidekiq::Web")

          lines = content.lines
          end_index = lines.rindex { |line| line.strip == "end" }
          return unless end_index

          lines.insert(end_index, SIDEKIQ_WEB_ROUTE_COMMENT)
          File.write(path, lines.join)
        end

        def add_top_level_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?(gem_line)

          File.open(gemfile_path, "a") { |f| f.puts(gem_line) }
        end
      end
    end
  end
end
