# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class DatabaseStep < Step
        def self.id = :database
        def self.summary = "Choose the database"
        def self.description = "Prompts for the database adapter (SQLite, PostgreSQL, MySQL)."
        def self.tier = :core
      end
    end
  end
end
