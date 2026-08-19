# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class FrontendStep < Step
        def self.id = :frontend
        def self.summary = "Choose the frontend stack"
        def self.description = "Prompts for React, Stimulus+Hotwire, or no frontend."
        def self.tier = :core
      end
    end
  end
end
