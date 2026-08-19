# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class MailerStep < Step
        def self.id = :mailer
        def self.summary = "Configure mailers"
        def self.description = "Sets up Letter Opener in development and Postmark in production."
      end
    end
  end
end
