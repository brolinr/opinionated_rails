# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class DatabaseStep < Step
        def self.id = :database
        def self.tier = :core
      end
    end
  end
end
