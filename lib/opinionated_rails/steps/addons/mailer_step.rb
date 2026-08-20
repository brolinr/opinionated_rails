# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class MailerStep < Step
        def self.id = :mailer
        def self.tier = :addon
        def self.needs = [ :secrets_handling ]
        def self.summary = "Configure mailers"
        def self.description = "Sets up Letter Opener in development and Postmark in production."
        def self.prompts = "Enable mailer setup (Letter Opener dev / Postmark production)? (default: yes)"

        LETTER_OPENER_VERSION = "1.10.0".freeze
        POSTMARK_RAILS_VERSION = "0.22.1".freeze

        DEVELOPMENT_ANCHOR = 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }'
        DEVELOPMENT_LINE = "config.action_mailer.delivery_method = :letter_opener"

        PRODUCTION_ANCHOR = 'config.action_mailer.default_url_options = { host: "example.com" }'

        POSTMARK_ENV_VAR_LINE = "POSTMARK_API_TOKEN="

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          choice = shell.ask("Enable mailer setup (Letter Opener dev / Postmark production)? (default: yes):").to_s.strip
          choice = "yes" if choice.empty?

          loop do
            case choice.downcase
            when "yes", "y"
              context.answer(:mailer, true)
              break
            when "no", "n"
              context.answer(:mailer, false)
              break
            else
              shell.say("Invalid. Enter 'yes' or 'no'.", :red)
              choice = shell.ask("Enable mailer setup (Letter Opener dev / Postmark production)? (default: yes):").to_s.strip
            end
          end
        end

        def generate(context)
          enabled = context.get(:mailer) != false

          if enabled
            add_development_group_gem(context, "gem \"letter_opener\", \"#{LETTER_OPENER_VERSION}\"")
            add_top_level_gem(context, "gem \"postmark-rails\", \"#{POSTMARK_RAILS_VERSION}\"")
            configure_development(context)
            configure_production(context)
            ensure_application_mailer(context)
          end

          context.set_output(:mailer, { mailer: enabled })
        end

        def outputs(context)
          context.output(:mailer)
        end

        private

        def configure_development(context)
          insert_after_anchor(
            File.join(context.app_path, "config/environments/development.rb"),
            DEVELOPMENT_ANCHOR,
            [ DEVELOPMENT_LINE ]
          )
        end

        def configure_production(context)
          insert_after_anchor(
            File.join(context.app_path, "config/environments/production.rb"),
            PRODUCTION_ANCHOR,
            production_lines(context)
          )
        end

        def production_lines(context)
          secrets_handling = context.output(:secrets_handling, :secrets_handling) || :rails_credentials

          api_token_line = case secrets_handling
          when :dotenv
            append_env_placeholder(context)
            'config.action_mailer.postmark_settings = { api_token: ENV["POSTMARK_API_TOKEN"] }'
          else
            "config.action_mailer.postmark_settings = { api_token: Rails.application.credentials.dig(:postmark, :api_token) }"
          end

          [ "config.action_mailer.delivery_method = :postmark", api_token_line ]
        end

        def append_env_placeholder(context)
          path = File.join(context.app_path, ".env.example")
          return unless File.exist?(path)

          content = File.read(path)
          return if content.include?(POSTMARK_ENV_VAR_LINE)

          File.open(path, "a") { |f| f.puts(POSTMARK_ENV_VAR_LINE) }
        end

        def insert_after_anchor(path, anchor, new_lines)
          return unless File.exist?(path)

          content = File.read(path)
          return if new_lines.all? { |line| content.include?(line) }

          lines = content.lines
          anchor_index = lines.index { |line| line.include?(anchor) }
          return unless anchor_index

          indent = lines[anchor_index][/\A\s*/]
          insertion = new_lines.map { |line| "#{indent}#{line}\n" }
          lines.insert(anchor_index + 1, *insertion)

          File.write(path, lines.join)
        end

        def ensure_application_mailer(context)
          path = File.join(context.app_path, "app/mailers/application_mailer.rb")
          return if File.exist?(path)

          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, <<~RUBY)
            class ApplicationMailer < ActionMailer::Base
              default from: "from@example.com"
              layout "mailer"
            end
          RUBY
        end

        def add_top_level_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?(gem_line)

          File.open(gemfile_path, "a") { |f| f.puts(gem_line) }
        end

        def add_development_group_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?(gem_line)

          lines = content.lines
          group_start = lines.index { |line| line.strip == "group :development do" }

          if group_start
            end_index = (group_start + 1...lines.size).find { |i| lines[i].strip == "end" }
            lines.insert(end_index, "  #{gem_line}\n")
          else
            lines << "\n" unless lines.last.nil? || lines.last.end_with?("\n")
            lines << "\ngroup :development do\n  #{gem_line}\nend\n"
          end

          File.write(gemfile_path, lines.join)
        end
      end
    end
  end
end
