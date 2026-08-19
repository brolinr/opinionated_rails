# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class SpaControllerStep < Step
        def self.id = :spa_controller
        def self.summary = "Add a SPA catch-all controller"
        def self.description = "Generates the always-present spa_controller.rb#root action."
      end
    end
  end
end
