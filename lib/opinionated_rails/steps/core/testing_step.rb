# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class TestingStep < Step
        def self.id = :testing
        def self.tier = :core
      end
    end
  end
end
