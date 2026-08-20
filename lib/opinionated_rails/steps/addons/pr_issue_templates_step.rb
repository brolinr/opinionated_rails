# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class PrIssueTemplatesStep < Step
        def self.id = :pr_issue_templates
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Generate GitHub templates"
        def self.description = "Adds default pull request and issue templates."
        def self.prompts = "None"

        TEMPLATES_DIR = File.expand_path("../../templates/github", __dir__)

        FILES = {
          "PULL_REQUEST_TEMPLATE.md" => ".github/PULL_REQUEST_TEMPLATE.md",
          "ISSUE_TEMPLATE/bug_report.md" => ".github/ISSUE_TEMPLATE/bug_report.md",
          "ISSUE_TEMPLATE/feature_request.md" => ".github/ISSUE_TEMPLATE/feature_request.md"
        }.freeze

        def if_condition(_context) = true

        def prompt(_context); end

        def generate(context)
          writer = OpinionatedRails::Generators::FileWriter.new

          FILES.each do |source, destination|
            content = File.read(File.join(TEMPLATES_DIR, source))
            writer.write(File.join(context.app_path, destination), content)
          end

          context.set_output(:pr_issue_templates, { pr_issue_templates: true })
        end

        def outputs(context)
          context.output(:pr_issue_templates)
        end
      end
    end
  end
end
