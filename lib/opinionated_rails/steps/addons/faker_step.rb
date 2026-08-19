# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class FakerStep < Step
        def self.id = :faker
        def self.summary = "Add Faker"
        def self.description = "Adds the Faker gem for generating fake data."
      end
    end
  end
end
