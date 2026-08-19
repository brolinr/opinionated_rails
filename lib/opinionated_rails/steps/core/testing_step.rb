# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class TestingStep < Step
        def self.id = :testing
        def self.summary = "Choose the test framework"
        def self.description = "Prompts for RSpec or Minitest as the test framework."
        def self.tier = :core
      end
    end
  end
end
