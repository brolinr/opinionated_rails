# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class ServicesStep < Step
        def self.id = :services
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Add an application service architecture"
        def self.description = "Installs an ApplicationService base class and an in-house Result object."
        def self.prompts = "Add an application service architecture? (default: no)"

        TEMPLATES_DIR = File.expand_path("../../templates/services", __dir__)

        FILES = {
          "application_service.rb" => "app/services/application_service.rb",
          "result.rb" => "app/services/result.rb"
        }.freeze

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          choice = shell.ask("Add an application service architecture? (default: no):").to_s.strip
          choice = "no" if choice.empty?

          loop do
            case choice.downcase
            when "yes", "y"
              context.answer(:services, true)
              break
            when "no", "n"
              context.answer(:services, false)
              break
            else
              shell.say("Invalid. Enter 'yes' or 'no'.", :red)
              choice = shell.ask("Add an application service architecture? (default: no):").to_s.strip
              choice = "no" if choice.empty?
            end
          end
        end

        def generate(context)
          enabled = context.get(:services) == true

          if enabled
            writer = OpinionatedRails::Generators::FileWriter.new
            FILES.each do |source, destination|
              content = File.read(File.join(TEMPLATES_DIR, source))
              writer.write(File.join(context.app_path, destination), content)
            end
          end

          context.set_output(:services, { services: enabled })
        end

        def outputs(context)
          context.output(:services)
        end
      end
    end
  end
end
