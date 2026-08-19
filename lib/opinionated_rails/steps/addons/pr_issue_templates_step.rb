# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class PrIssueTemplatesStep < Step
        def self.id = :pr_issue_templates
        def self.summary = "Generate GitHub templates"
        def self.description = "Adds default pull request and issue templates."
      end
    end
  end
end
