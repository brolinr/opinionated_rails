# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class CompilingStep < Step
        def self.id = :compiling
        def self.summary = "Configure asset compiling"
        def self.description = "Sets up esbuild (React) or Propshaft with importmap-rails (non-React UI)."
      end
    end
  end
end
