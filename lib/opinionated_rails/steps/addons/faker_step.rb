# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class FakerStep < Step
        def self.id = :faker
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Add Faker"
        def self.description = "Adds the Faker gem for generating fake data."
        def self.prompts = "None"

        FAKER_VERSION = "3.8.0".freeze

        def if_condition(_context) = true

        def prompt(_context); end

        def generate(context)
          add_dev_test_group_gem(context, "gem \"faker\", \"#{FAKER_VERSION}\"")

          context.set_output(:faker, { faker: true })
        end

        def outputs(context)
          context.output(:faker)
        end

        private

        def add_dev_test_group_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?(gem_line)

          lines = content.lines
          group_start = lines.index { |line| line.strip == "group :development, :test do" }

          if group_start
            end_index = (group_start + 1...lines.size).find { |i| lines[i].strip == "end" }
            lines.insert(end_index, "  #{gem_line}\n")
          else
            lines << "\n" unless lines.last.nil? || lines.last.end_with?("\n")
            lines << "\ngroup :development, :test do\n  #{gem_line}\nend\n"
          end

          File.write(gemfile_path, lines.join)
        end
      end
    end
  end
end
