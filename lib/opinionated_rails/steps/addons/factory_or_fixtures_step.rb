# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class FactoryOrFixturesStep < Step
        def self.id = :factory_or_fixtures
        def self.tier = :addon
        def self.needs = [ :testing ]
        def self.summary = "Configure factories or fixtures"
        def self.description = "Adds FactoryBot for RSpec or keeps Minitest fixtures."
        def self.prompts = "FactoryBot or Fixtures for RSpec (default: FactoryBot)"

        FACTORY_BOT_VERSION = "6.4.3".freeze

        MINIMAL_RAILS_HELPER = <<~RUBY
          require 'spec_helper'
          ENV['RAILS_ENV'] ||= 'test'
          require_relative '../config/environment'
          require 'rspec/rails'

          RSpec.configure do |config|
            config.fixture_paths = [
              Rails.root.join('spec/fixtures')
            ]
            config.use_transactional_fixtures = true
          end
        RUBY

        def if_condition(context)
          context.output(:testing, :test_framework) == :rspec
        end

        def prompt(context)
          shell = context.shell
          shell.say("Choose a factory/fixture strategy for RSpec:")
          shell.say("  1. FactoryBot (default)")
          shell.say("  2. Fixtures")

          choice = shell.ask("Factory strategy (default: FactoryBot):").to_s.strip
          choice = "1" if choice.empty?

          loop do
            case choice.downcase
            when "factorybot", "factory_bot", "1"
              context.answer(:factory_or_fixtures, :factory_bot)
              break
            when "fixtures", "2"
              context.answer(:factory_or_fixtures, :fixtures)
              break
            else
              shell.say("Invalid. Enter 'FactoryBot', 'Fixtures', 1, or 2.", :red)
              choice = shell.ask("Factory strategy (default: FactoryBot):").to_s.strip
            end
          end
        end

        def generate(context)
          unless if_condition(context)
            context.set_output(:factory_or_fixtures, nil)
            return
          end

          strategy = context.get(:factory_or_fixtures) || :factory_bot
          install_factory_bot(context) if strategy == :factory_bot

          context.set_output(:factory_or_fixtures, { factory_or_fixtures: strategy })
        end

        def outputs(context)
          context.output(:factory_or_fixtures)
        end

        private

        def install_factory_bot(context)
          add_test_group_gem(context, "gem \"factory_bot_rails\", \"#{FACTORY_BOT_VERSION}\"")
          FileUtils.mkdir_p(File.join(context.app_path, "spec/factories"))
          ensure_rails_helper(context)
          include_factory_bot_syntax(context)
        end

        def add_test_group_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?(gem_line)

          lines = content.lines
          group_start = lines.index { |line| line.strip == "group :test do" }

          if group_start
            end_index = (group_start + 1...lines.size).find { |i| lines[i].strip == "end" }
            lines.insert(end_index, "  #{gem_line}\n")
          else
            lines << "\n" unless lines.last.nil? || lines.last.end_with?("\n")
            lines << "\ngroup :test do\n  #{gem_line}\nend\n"
          end

          File.write(gemfile_path, lines.join)
        end

        def ensure_rails_helper(context)
          rails_helper_path = File.join(context.app_path, "spec/rails_helper.rb")
          return if File.exist?(rails_helper_path)

          FileUtils.mkdir_p(File.dirname(rails_helper_path))
          File.write(rails_helper_path, MINIMAL_RAILS_HELPER)
        end

        def include_factory_bot_syntax(context)
          rails_helper_path = File.join(context.app_path, "spec/rails_helper.rb")
          content = File.read(rails_helper_path)
          return if content.include?("FactoryBot::Syntax::Methods")

          lines = content.lines
          end_index = lines.rindex { |line| line.strip == "end" }
          return unless end_index

          lines.insert(end_index, "  config.include FactoryBot::Syntax::Methods\n")
          File.write(rails_helper_path, lines.join)
        end
      end
    end
  end
end
