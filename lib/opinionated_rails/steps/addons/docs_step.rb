# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class DocsStep < Step
        def self.id = :docs
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Generate project documentation"
        def self.description = "Creates AGENT.md and STYLE.md files."
        def self.prompts = "None"

        AGENT_TEXT = "Read STYLE.md before making any changes to this codebase."
        STYLE_TEMPLATE = File.expand_path("../../templates/docs/STYLE.md", __dir__)

        def if_condition(_context) = true

        def prompt(_context); end

        def generate(context)
          writer = OpinionatedRails::Generators::FileWriter.new
          writer.write(File.join(context.app_path, "AGENT.md"), AGENT_TEXT)
          writer.write(File.join(context.app_path, "STYLE.md"), File.read(STYLE_TEMPLATE))

          context.set_output(:docs, { docs: true })
        end

        def outputs(context)
          context.output(:docs)
        end
      end
    end
  end
end
