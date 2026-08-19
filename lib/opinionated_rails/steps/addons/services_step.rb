# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class ServicesStep < Step
        def self.id = :services_architecture
        def self.summary = "Add an application service architecture"
        def self.description = "Installs an ApplicationService base class and an in-house Result object."
      end
    end
  end
end
