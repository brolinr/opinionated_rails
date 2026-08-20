# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class StagingEnvStep < Step
        def self.id = :staging_env
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Add staging environment"
        def self.description = "Creates a staging Rails environment file and configuration."
        def self.prompts = "Add a staging environment? (default: no)"

        REVIEW_COMMENT = <<~RUBY
          # Seeded from config/environments/production.rb by opinionated_rails.
          # Review and adjust host names, credentials scoping, and any production-only
          # assumptions before using this environment.

        RUBY

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          choice = shell.ask("Add a staging environment? (default: no):").to_s.strip
          choice = "no" if choice.empty?

          loop do
            case choice.downcase
            when "yes", "y"
              context.answer(:staging_env, true)
              break
            when "no", "n"
              context.answer(:staging_env, false)
              break
            else
              shell.say("Invalid. Enter 'yes' or 'no'.", :red)
              choice = shell.ask("Add a staging environment? (default: no):").to_s.strip
            end
          end
        end

        def generate(context)
          enabled = context.get(:staging_env) == true

          write_staging_environment(context) if enabled

          context.set_output(:staging_env, { staging_env: enabled })
        end

        def outputs(context)
          context.output(:staging_env)
        end

        private

        def write_staging_environment(context)
          production_path = File.join(context.app_path, "config/environments/production.rb")
          return unless File.exist?(production_path)

          staging_path = File.join(context.app_path, "config/environments/staging.rb")
          File.write(staging_path, REVIEW_COMMENT + File.read(production_path))
        end
      end
    end
  end
end
