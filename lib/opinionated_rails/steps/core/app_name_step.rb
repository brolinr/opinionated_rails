# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class AppNameStep < Step
        def self.id = :app_name
        def self.summary = "Set the application name"
        def self.description = "Records the Rails application name used for the generated app."
        def self.tier = :core
      end
    end
  end
end
