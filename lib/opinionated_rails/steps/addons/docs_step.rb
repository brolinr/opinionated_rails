# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class DocsStep < Step
        def self.id = :docs
        def self.summary = "Generate project documentation"
        def self.description = "Creates AGENT.md and STYLE.md files."
      end
    end
  end
end
