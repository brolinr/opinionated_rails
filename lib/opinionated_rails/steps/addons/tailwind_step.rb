# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class TailwindStep < Step
        def self.id = :tailwind
        def self.summary = "Configure Tailwind CSS"
        def self.description = "Installs Tailwind v3 with a path appropriate for the chosen frontend."
      end
    end
  end
end
