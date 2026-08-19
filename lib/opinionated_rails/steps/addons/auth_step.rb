# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class AuthStep < Step
        def self.id = :auth
        def self.summary = "Configure authentication"
        def self.description = "Prompts for a user model name and chooses Rails 8 built-in, Devise, or none."
      end
    end
  end
end
