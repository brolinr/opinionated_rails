# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class VcrStep < Step
        def self.id = :vcr
        def self.summary = "Configure VCR"
        def self.description = "Installs VCR for recording and replaying HTTP interactions in tests."
      end
    end
  end
end
