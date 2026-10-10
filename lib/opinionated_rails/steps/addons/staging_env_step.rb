# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class StagingEnvStep < Step
        def self.id = :staging_env
        def self.tier = :addon
        # Staging is seeded from production, so it must run after every step that edits
        # production.rb / database.yml / cable.yml (stack swap, mailer, Docker).
        def self.needs = [ :solid_stack, :mailer, :docker_kamal ]
        def self.summary = "Add staging environment"
        def self.description = "Creates a staging Rails environment file and configuration."
        def self.prompts = "Add a staging environment? (default: no)"

        REVIEW_COMMENT = <<~RUBY
          # Seeded from config/environments/production.rb by opinionated_rails.
          # Review and adjust host names, credentials scoping, and any production-only
          # assumptions before using this environment.

        RUBY

        MAIL_NOTICE = <<~RUBY
          # Staging must not send real email through the production Postmark account. To test delivery,
          # create a separate Postmark server for staging and use its token:
          #   config.action_mailer.delivery_method = :postmark
          #   config.action_mailer.postmark_settings = { api_token: ENV["POSTMARK_STAGING_API_TOKEN"] }
        RUBY

        # Files with a top-level `production:` block that needs a `staging:` twin; without it
        # `RAILS_ENV=staging` fails to boot (e.g. solid_cable reading cable.yml).
        STAGING_YAML_FILES = %w[ database cable cache queue recurring ].map { |name| "config/#{name}.yml" }.freeze

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
              choice = "no" if choice.empty?
            end
          end
        end

        def generate(context)
          enabled = context.get(:staging_env) == true

          if enabled
            write_staging_environment(context)
            STAGING_YAML_FILES.each { |file| add_staging_yaml_block(File.join(context.app_path, file)) }
          end

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
          File.write(staging_path, REVIEW_COMMENT + isolate_mail(File.read(production_path)))
        end

        # Seeded from production, staging would deliver real email through the production Postmark account.
        def isolate_mail(content)
          content.gsub(/^(\s*)config\.action_mailer\.delivery_method = :postmark\n/) do
            indent = Regexp.last_match(1)
            MAIL_NOTICE.lines.map { |line| "#{indent}#{line}" }.join + "#{indent}config.action_mailer.delivery_method = :test\n"
          end.gsub(/^\s*config\.action_mailer\.postmark_settings = .*\n/, "")
        end

        def add_staging_yaml_block(path)
          return unless File.exist?(path)

          lines = File.read(path).lines
          return if lines.any? { |line| line.start_with?("staging:") }

          start = lines.index { |line| line.start_with?("production:") }
          return unless start

          finish = (start + 1...lines.size).find { |i| lines[i].match?(/\A\S/) } || lines.size
          block = lines[start...finish].join.rstrip.gsub("production", "staging")

          lines[-1] = "#{lines.last.chomp}\n" unless lines.empty?
          File.write(path, "#{lines.join}\n#{block}\n")
        end
      end
    end
  end
end
