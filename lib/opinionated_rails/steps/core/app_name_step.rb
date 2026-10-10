# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class AppNameStep < Step
        def self.id = :app_name
        def self.summary = "Set the application name"
        def self.description = "Records the Rails application name used for the generated app."
        def self.tier = :core
        def self.prompts = "App name (free text, valid Ruby constant once camelized, no leading digit)"

        RESERVED_NAMES = %w[ test application ].freeze

        def prompt(context)
          return if preset_name?(context)

          loop do
            raw = context.shell.ask("App name:")
            raise OpinionatedRails::Error, "No app name given (input ended)" if raw.nil?

            normalized = normalize(raw)
            errors = validate(normalized)

            if errors.empty?
              context.answer(:app_name, normalized)
              break
            end

            context.shell.say("Invalid: #{errors.join(', ')}", :red)
          end
        end

        # `opinionated_rails new my_app` supplies the name up front; fall back to asking if it's invalid.
        def preset_name?(context)
          preset = context.get(:app_name_input)
          return false if preset.to_s.strip.empty?

          normalized = normalize(preset)
          errors = validate(normalized)
          if errors.empty?
            context.answer(:app_name, normalized)
            return true
          end

          context.shell.say("Invalid app name #{preset.inspect}: #{errors.join(', ')}", :red)
          false
        end

        def generate(context)
          name = context.get(:app_name)
          errors = validate(name)

          raise ArgumentError, "Invalid app name: #{errors.join(', ')}" unless errors.empty?

          context.set_output(:app_name, { app_name: name })
        end

        def outputs(context)
          context.output(:app_name)
        end

        private

        def normalize(raw)
          raw.to_s.strip.downcase.gsub(/[-\s]+/, "_").gsub(/[^a-z0-9_]/, "")
        end

        def validate(name)
          errors = []
          errors << "cannot be blank" if name.empty?
          errors << "must start with a letter" if name.match?(/\A\d/)
          errors << "must contain only letters, digits, underscores and hyphens" unless name.match?(/\A[a-z0-9_-]*\z/)
          errors << "is a reserved name" if RESERVED_NAMES.include?(name)
          errors << "collides with an existing constant" if name.match?(/\A[a-z]/) && Object.const_defined?(camelize(name))
          errors
        end

        def camelize(name)
          name.split("_").map(&:capitalize).join
        end
      end
    end
  end
end
