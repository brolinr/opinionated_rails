# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class RubocopStep < Step
        def self.id = :rubocop
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Configure RuboCop"
        def self.description = "Installs and configures RuboCop with Omakase defaults or a custom setup."
        def self.prompts = "RuboCop style: Omakase or Custom (default: Omakase)"

        RUBOCOP_OMAKASE_VERSION = "1.1.0".freeze
        UNPINNED_GEM_LINE = 'gem "rubocop-rails-omakase", require: false'
        CUSTOM_OVERRIDES_TEMPLATE = File.expand_path("../../templates/rubocop/custom_overrides.yml", __dir__)

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          shell.say("Choose a RuboCop style:")
          shell.say("  1. Omakase (default)")
          shell.say("  2. Custom")

          choice = shell.ask("RuboCop style (default: Omakase):").to_s.strip
          choice = "1" if choice.empty?

          loop do
            case choice.downcase
            when "omakase", "1"
              context.answer(:rubocop, :omakase)
              break
            when "custom", "2"
              context.answer(:rubocop, :custom)
              break
            else
              shell.say("Invalid. Enter 'Omakase', 'Custom', 1, or 2.", :red)
              choice = shell.ask("RuboCop style (default: Omakase):").to_s.strip
            end
          end
        end

        def generate(context)
          style = context.get(:rubocop) || :omakase

          pin_rubocop_gem(context)
          write_custom_overrides(context) if style == :custom

          context.set_output(:rubocop, { rubocop: style })
        end

        def outputs(context)
          context.output(:rubocop)
        end

        private

        def pin_rubocop_gem(context)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          pinned_line = "gem \"rubocop-rails-omakase\", \"#{RUBOCOP_OMAKASE_VERSION}\", require: false"
          content = File.read(gemfile_path)
          return if content.include?(pinned_line)

          if content.include?(UNPINNED_GEM_LINE)
            File.write(gemfile_path, content.sub(UNPINNED_GEM_LINE, pinned_line))
          else
            add_dev_test_group_gem(context, pinned_line)
          end
        end

        def add_dev_test_group_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
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

        def write_custom_overrides(context)
          rubocop_yml_path = File.join(context.app_path, ".rubocop.yml")
          overrides = File.read(CUSTOM_OVERRIDES_TEMPLATE)

          content = <<~YAML
            # Omakase Ruby styling for Rails
            inherit_gem: { rubocop-rails-omakase: rubocop.yml }

            # --- user overrides below ---
            #{overrides}
          YAML

          File.write(rubocop_yml_path, content)
        end
      end
    end
  end
end
