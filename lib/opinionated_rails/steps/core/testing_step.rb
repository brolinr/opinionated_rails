# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class TestingStep < Step
        def self.id = :testing
        def self.summary = "Choose the test framework"
        def self.description = "Prompts for RSpec or Minitest as the test framework."
        def self.tier = :core
        def self.prompts = "Test framework: RSpec or Minitest (default: Minitest)"

        RSPEC_VERSION = "6.1.0".freeze

        def prompt(context)
          shell = context.shell
          shell.say("Choose a test framework:")
          shell.say("  1. Minitest")
          shell.say("  2. RSpec")

          choice = shell.ask("Test framework (default: Minitest):").to_s.strip
          choice = "minitest" if choice.empty?

          loop do
            case choice.downcase
            when "minitest", "1"
              context.answer(:testing, :minitest)
              break
            when "rspec", "2"
              context.answer(:testing, :rspec)
              break
            else
              shell.say("Invalid. Enter 'Minitest', 'RSpec', 1, or 2.", :red)
              choice = shell.ask("Test framework (default: Minitest):").to_s.strip
            end
          end
        end

        def generate(context)
          framework = context.get(:testing)
          raise ArgumentError, "No test framework answer" unless framework

          context.set_output(:testing, { test_framework: framework })
          install_rspec(context) if framework == :rspec
        end

        def outputs(context)
          context.output(:testing)
        end

        private

        def install_rspec(context)
          gemfile = File.join(context.app_path, "Gemfile")
          File.open(gemfile, "a") { |f| f.puts("gem \"rspec-rails\", \"#{RSPEC_VERSION}\"") }

          return if context.skip_bundle_install

          Dir.chdir(context.app_path) do
            system("bundle", "exec", "rails", "generate", "rspec:install") ||
              raise(OpinionatedRails::Error, "rspec:install failed")
          end
        end
      end
    end
  end
end
