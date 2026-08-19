# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class CiStep < Step
        def self.id = :ci
        def self.summary = "Configure CI"
        def self.description = "Generates GitHub Actions workflows for tests and RuboCop."
      end
    end
  end
end
