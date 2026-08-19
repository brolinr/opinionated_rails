# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class FrontendStep < Step
        def self.id = :frontend
        def self.tier = :core
      end
    end
  end
end
