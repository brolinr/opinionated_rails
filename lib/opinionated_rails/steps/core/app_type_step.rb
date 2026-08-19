# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class AppTypeStep < Step
        def self.id = :app_type
        def self.summary = "Choose API-only or full-stack"
        def self.description = "Decides whether the app is API-only or a full-stack Rails app."
        def self.tier = :core
      end
    end
  end
end
