# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class AppTypeStep < Step
        def self.id = :app_type
        def self.summary = "Choose API-only or full-stack"
        def self.description = "Decides whether the app is API-only or a full-stack Rails app."
        def self.tier = :core
        def self.prompts = "App type: API-only or Full-stack (default: Full-stack)"

        def prompt(context)
          shell = context.shell
          shell.say("Choose an app type:")
          shell.say("  1. Full-stack")
          shell.say("  2. API-only")

          choice = shell.ask("App type (default: Full-stack):").to_s.strip
          choice = "full-stack" if choice.empty?

          loop do
            case choice.downcase
            when "full-stack", "1"
              context.answer(:app_type, :full_stack)
              break
            when "api-only", "2"
              context.answer(:app_type, :api_only)
              break
            else
              shell.say("Invalid. Enter 'Full-stack', 'API-only', 1, or 2.", :red)
              choice = shell.ask("App type (default: Full-stack):").to_s.strip
            end
          end
        end

        def generate(context)
          type = context.get(:app_type)
          raise ArgumentError, "No app type answer" unless type

          context.set_output(:app_type, { app_type: type })
        end

        def outputs(context)
          context.output(:app_type)
        end
      end
    end
  end
end
