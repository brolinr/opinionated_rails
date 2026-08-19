# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class StagingEnvStep < Step
        def self.id = :staging_env
        def self.summary = "Add staging environment"
        def self.description = "Creates a staging Rails environment file and configuration."
      end
    end
  end
end
