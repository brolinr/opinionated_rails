# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class DatabaseStep < Step
        def self.id = :database
        def self.summary = "Choose the database"
        def self.description = "Prompts for the database adapter (SQLite, PostgreSQL, MySQL)."
        def self.tier = :core
        def self.prompts = "Database adapter: SQLite, PostgreSQL, or MySQL (default: SQLite)"

        ADAPTERS = {
          "sqlite" => :sqlite3,
          "postgresql" => :postgresql,
          "mysql" => :mysql2
        }.freeze

        DISPLAY_NAMES = %w[ SQLite PostgreSQL MySQL ].freeze

        def prompt(context)
          shell = context.shell
          shell.say("Choose a database:")
          DISPLAY_NAMES.each_with_index { |name, index| shell.say("  #{index + 1}. #{name}") }

          loop do
            choice = shell.ask("Database (default: SQLite):").to_s.strip.downcase
            choice = "sqlite" if choice.empty?
            choice = ADAPTERS.keys[choice.to_i - 1] if %w[1 2 3].include?(choice)

            if ADAPTERS.key?(choice)
              context.answer(:database, ADAPTERS[choice])
              break
            end

            shell.say("Invalid choice. Enter #{DISPLAY_NAMES.join(', ')}.", :red)
          end
        end

        def generate(context)
          adapter = context.get(:database)
          raise ArgumentError, "No database answer" unless adapter

          context.set_output(:database, { database: adapter })
        end

        def outputs(context)
          context.output(:database)
        end
      end
    end
  end
end
