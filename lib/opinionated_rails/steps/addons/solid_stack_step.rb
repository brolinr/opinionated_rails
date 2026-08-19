# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class SolidStackStep < Step
        def self.id = :solid_stack
        def self.summary = "Configure Solid Trifecta"
        def self.description = "Sets up Solid Queue, Solid Cache, and Solid Cable for background jobs, caching, and Action Cable."
      end
    end
  end
end
