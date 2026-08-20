# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class DockerKamalStep < Step
        def self.id = :docker_kamal
        def self.tier = :addon
        def self.needs = [ :database, :frontend ]
        def self.summary = "Configure Docker and Kamal"
        def self.description = "Generates a Dockerfile and optional Kamal deployment files."
        def self.prompts = "Enable Kamal deployment? (default: no) — Docker itself is always generated"

        DOCKERFILE_RAILS_VERSION = "1.7.10".freeze
        KAMAL_VERSION = "2.12.0".freeze

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          choice = shell.ask("Enable Kamal deployment? (default: no):").to_s.strip
          choice = "no" if choice.empty?

          loop do
            case choice.downcase
            when "yes", "y"
              context.answer(:docker_kamal, true)
              break
            when "no", "n"
              context.answer(:docker_kamal, false)
              break
            else
              shell.say("Invalid. Enter 'yes' or 'no'.", :red)
              choice = shell.ask("Enable Kamal deployment? (default: no):").to_s.strip
            end
          end
        end

        def generate(context)
          kamal_enabled = context.get(:docker_kamal) == true

          install_dockerfile_rails(context)
          install_kamal(context) if kamal_enabled

          context.set_output(:docker_kamal, { docker: true, kamal: kamal_enabled })
        end

        def outputs(context)
          context.output(:docker_kamal)
        end

        private

        def install_dockerfile_rails(context)
          add_development_group_gem(context, "gem \"dockerfile-rails\", \"#{DOCKERFILE_RAILS_VERSION}\"")

          return if context.skip_bundle_install

          run_in_app(context, "bundle", "install", "--quiet") ||
            raise(OpinionatedRails::Error, "bundle install failed")
          run_in_app(context, "bundle", "exec", "rails", "generate", "dockerfile", "--force") ||
            raise(OpinionatedRails::Error, "rails generate dockerfile failed")
        end

        def install_kamal(context)
          add_top_level_gem(context, "gem \"kamal\", \"#{KAMAL_VERSION}\"")

          return if context.skip_bundle_install

          run_in_app(context, "bundle", "install", "--quiet") ||
            raise(OpinionatedRails::Error, "bundle install failed")
          run_in_app(context, "bundle", "exec", "kamal", "init") ||
            raise(OpinionatedRails::Error, "kamal init failed")
        end

        def run_in_app(context, *command)
          Dir.chdir(context.app_path) do
            if defined?(Bundler)
              Bundler.with_unbundled_env { system(*command) }
            else
              system(*command)
            end
          end
        end

        def add_top_level_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?(gem_line)

          File.open(gemfile_path, "a") { |f| f.puts(gem_line) }
        end

        def add_development_group_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?(gem_line)

          lines = content.lines
          group_start = lines.index { |line| line.strip == "group :development do" }

          if group_start
            end_index = (group_start + 1...lines.size).find { |i| lines[i].strip == "end" }
            lines.insert(end_index, "  #{gem_line}\n")
          else
            lines << "\n" unless lines.last.nil? || lines.last.end_with?("\n")
            lines << "\ngroup :development do\n  #{gem_line}\nend\n"
          end

          File.write(gemfile_path, lines.join)
        end
      end
    end
  end
end
