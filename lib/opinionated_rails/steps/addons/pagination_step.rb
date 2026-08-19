# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class PaginationStep < Step
        def self.id = :pagination
        def self.summary = "Configure pagination"
        def self.description = "Installs geared_pagination or pagy for paginated collections."
      end
    end
  end
end
