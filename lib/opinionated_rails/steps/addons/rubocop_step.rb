# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class RubocopStep < Step
        def self.id = :rubocop
        def self.summary = "Configure RuboCop"
        def self.description = "Installs and configures RuboCop with Omakase defaults or a custom setup."
      end
    end
  end
end
