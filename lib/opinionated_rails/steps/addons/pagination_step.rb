# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class PaginationStep < Step
        def self.id = :pagination
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Configure pagination"
        def self.description = "Installs geared_pagination or pagy for paginated collections."
        def self.prompts = "Pagination: geared_pagination or pagy (default: pagy)"

        GEARED_PAGINATION_VERSION = "1.2.0".freeze
        PAGY_VERSION = "43.6.1".freeze

        PAGY_INITIALIZER = <<~RUBY
          # frozen_string_literal: true

          # Pagy initializer — see https://ddnexus.github.io/pagy/toolbox/configuration/initializer/
          # for the full list of available options.

          Pagy::OPTIONS.freeze
        RUBY

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          shell.say("Choose a pagination library:")
          shell.say("  1. geared_pagination")
          shell.say("  2. pagy (default)")

          choice = shell.ask("Pagination (default: pagy):").to_s.strip
          choice = "2" if choice.empty?

          loop do
            case choice.downcase
            when "geared_pagination", "1"
              context.answer(:pagination, :geared_pagination)
              break
            when "pagy", "2"
              context.answer(:pagination, :pagy)
              break
            else
              shell.say("Invalid. Enter 'geared_pagination', 'pagy', 1, or 2.", :red)
              choice = shell.ask("Pagination (default: pagy):").to_s.strip
            end
          end
        end

        def generate(context)
          strategy = context.get(:pagination) || :pagy

          if strategy == :pagy
            install_pagy(context)
          else
            install_geared_pagination(context)
          end

          context.set_output(:pagination, { pagination: strategy })
        end

        def outputs(context)
          context.output(:pagination)
        end

        private

        def install_geared_pagination(context)
          add_top_level_gem(context, "gem \"geared_pagination\", \"#{GEARED_PAGINATION_VERSION}\"")
        end

        def install_pagy(context)
          add_top_level_gem(context, "gem \"pagy\", \"#{PAGY_VERSION}\"")
          write_pagy_initializer(context)
          include_module(context, "app/controllers/application_controller.rb", "ApplicationController", "Pagy::Backend")
          include_module(context, "app/helpers/application_helper.rb", "ApplicationHelper", "Pagy::Frontend")
        end

        def write_pagy_initializer(context)
          path = File.join(context.app_path, "config/initializers/pagy.rb")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, PAGY_INITIALIZER)
        end

        def include_module(context, relative_path, class_or_module_name, module_to_include)
          path = File.join(context.app_path, relative_path)
          return unless File.exist?(path)

          content = File.read(path)
          include_line = "include #{module_to_include}"
          return if content.include?(include_line)

          lines = content.lines
          open_index = lines.index { |line| line.match?(/\A(class|module)\s+#{Regexp.escape(class_or_module_name)}\b/) }
          return unless open_index

          lines.insert(open_index + 1, "  #{include_line}\n")
          File.write(path, lines.join)
        end

        def add_top_level_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?(gem_line)

          File.open(gemfile_path, "a") { |f| f.puts(gem_line) }
        end
      end
    end
  end
end
