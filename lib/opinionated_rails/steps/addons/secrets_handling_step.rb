# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class SecretsHandlingStep < Step
        def self.id = :secrets_handling
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Configure secrets handling"
        def self.description = "Chooses Rails encrypted credentials or dotenv for managing secrets."
        def self.prompts = "Secrets handling: Rails credentials or dotenv (default: Rails credentials)"

        DOTENV_RAILS_VERSION = "3.2.0".freeze

        ENV_EXAMPLE_HEADER = <<~ENV
          # Copy this file to .env and fill in real values locally.
          # .env is gitignored; this file (.env.example) is committed with placeholders only.
        ENV

        ENV_GLOB_PATTERNS = %w[ .env* /.env* ].freeze
        ENV_IGNORE_PATTERNS = (%w[ .env /.env ] + ENV_GLOB_PATTERNS).freeze
        ENV_EXAMPLE_UNIGNORE = %w[ !.env.example !/.env.example ].freeze

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          shell.say("Choose how secrets are handled:")
          shell.say("  1. Rails credentials (default)")
          shell.say("  2. dotenv")

          choice = shell.ask("Secrets handling (default: Rails credentials):").to_s.strip
          choice = "1" if choice.empty?

          loop do
            case choice.downcase
            when "rails credentials", "rails_credentials", "1"
              context.answer(:secrets_handling, :rails_credentials)
              break
            when "dotenv", "2"
              context.answer(:secrets_handling, :dotenv)
              break
            else
              shell.say("Invalid. Enter 'Rails credentials', 'dotenv', 1, or 2.", :red)
              choice = shell.ask("Secrets handling (default: Rails credentials):").to_s.strip
              choice = "1" if choice.empty?
            end
          end
        end

        def generate(context)
          strategy = context.get(:secrets_handling) || :rails_credentials

          case strategy
          when :dotenv
            install_dotenv(context)
          else
            check_rails_credentials(context)
          end

          context.set_output(:secrets_handling, { secrets_handling: strategy })
        end

        def outputs(context)
          context.output(:secrets_handling)
        end

        private

        def check_rails_credentials(context)
          master_key = File.join(context.app_path, "config/master.key")
          credentials = File.join(context.app_path, "config/credentials.yml.enc")
          return if File.exist?(master_key) && File.exist?(credentials)

          context.shell.say(
            "Warning: config/master.key or config/credentials.yml.enc is missing — Rails credentials may not work as expected.",
            :yellow
          )
        end

        def install_dotenv(context)
          add_dev_test_group_gem(context, "gem \"dotenv-rails\", \"#{DOTENV_RAILS_VERSION}\"")
          write_env_example(context)
          gitignore_dotenv(context)
        end

        def write_env_example(context)
          path = File.join(context.app_path, ".env.example")
          return if File.exist?(path)

          File.write(path, ENV_EXAMPLE_HEADER)
        end

        def gitignore_dotenv(context)
          path = File.join(context.app_path, ".gitignore")
          return unless File.exist?(path)

          content = File.read(path)
          patterns = content.lines.map(&:strip)
          additions = []
          additions << ".env" unless patterns.intersect?(ENV_IGNORE_PATTERNS)
          # A glob like `.env*` would also hide the committed template.
          if patterns.intersect?(ENV_GLOB_PATTERNS) && !patterns.intersect?(ENV_EXAMPLE_UNIGNORE)
            additions << "!/.env.example"
          end
          return if additions.empty?

          File.open(path, "a") do |f|
            f.print("\n") unless content.empty? || content.end_with?("\n")
            additions.each { |line| f.puts(line) }
          end
        end

        def add_dev_test_group_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?(gem_line)

          lines = content.lines
          group_start = lines.index { |line| line.strip == "group :development, :test do" }

          if group_start
            end_index = (group_start + 1...lines.size).find { |i| lines[i].strip == "end" }
            lines.insert(end_index, "  #{gem_line}\n")
          else
            lines << "\n" unless lines.last.nil? || lines.last.end_with?("\n")
            lines << "\ngroup :development, :test do\n  #{gem_line}\nend\n"
          end

          File.write(gemfile_path, lines.join)
        end
      end
    end
  end
end
