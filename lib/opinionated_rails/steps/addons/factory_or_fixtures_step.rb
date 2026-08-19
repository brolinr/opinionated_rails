# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class FactoryOrFixturesStep < Step
        def self.id = :factorybot
        def self.summary = "Configure factories or fixtures"
        def self.description = "Adds FactoryBot for RSpec or keeps Minitest fixtures."
      end
    end
  end
end
