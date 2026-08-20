# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class TailwindStep < Step
        def self.id = :tailwind
        def self.tier = :addon
        def self.needs = [ :frontend ]
        def self.summary = "Configure Tailwind CSS"
        def self.description = "Installs Tailwind v3 with a path appropriate for the chosen frontend."
        def self.prompts = "None"

        TAILWIND_VERSION = "3.4.1".freeze
        TAILWIND_RAILS_VERSION = "3.3.0".freeze

        DIRECTIVES = <<~CSS
          @tailwind base;
          @tailwind components;
          @tailwind utilities;
        CSS

        def if_condition(context)
          context.output(:frontend, :frontend) != :none
        end

        def prompt(_context); end

        def generate(context)
          unless if_condition(context)
            context.set_output(:tailwind, nil)
            return
          end

          if context.output(:frontend, :frontend) == :react
            configure_for_react(context)
          else
            configure_for_stimulus(context)
          end

          write_stylesheet(context)
          update_layout(context)

          context.set_output(:tailwind, { tailwind: true })
        end

        def outputs(context)
          context.output(:tailwind)
        end

        private

        def configure_for_stimulus(context)
          gemfile = File.join(context.app_path, "Gemfile")
          if File.exist?(gemfile) && !File.read(gemfile).include?("tailwindcss-rails")
            File.open(gemfile, "a") { |f| f.puts("gem \"tailwindcss-rails\", \"#{TAILWIND_RAILS_VERSION}\"") }
          end

          write_tailwind_config(context, stimulus_content)
          append_procfile(context, "css: bin/rails tailwindcss:watch")
        end

        def configure_for_react(context)
          package_json_path = File.join(context.app_path, "package.json")
          package = File.exist?(package_json_path) ? JSON.parse(File.read(package_json_path)) : {}

          package["devDependencies"] ||= {}
          package["devDependencies"]["tailwindcss"] = TAILWIND_VERSION

          package["scripts"] ||= {}
          package["scripts"]["build:css"] = "npx tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/tailwind.css --minify"

          File.write(package_json_path, JSON.pretty_generate(package))

          write_tailwind_config(context, react_content)
          append_procfile(context, "css: npx tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/tailwind.css --watch")
        end

        def write_stylesheet(context)
          css_path = File.join(context.app_path, "app/assets/stylesheets/application.tailwind.css")
          FileUtils.mkdir_p(File.dirname(css_path))
          File.write(css_path, DIRECTIVES)
        end

        def write_tailwind_config(context, content)
          config_path = File.join(context.app_path, "config/tailwind.config.js")
          FileUtils.mkdir_p(File.dirname(config_path))
          File.write(config_path, content)
        end

        def stimulus_content
          <<~JS
            module.exports = {
              content: [
                "./app/views/**/*.html.erb",
                "./app/helpers/**/*.rb",
                "./app/javascript/**/*.js",
                "./app/assets/stylesheets/**/*.css"
              ],
              theme: {},
              plugins: []
            }
          JS
        end

        def react_content
          <<~JS
            module.exports = {
              content: ["./app/javascript/**/*.{js,jsx}"],
              theme: {},
              plugins: []
            }
          JS
        end

        def append_procfile(context, line)
          procfile = File.join(context.app_path, "Procfile.dev")

          if File.exist?(procfile)
            content = File.read(procfile)
            return if content.include?(line)

            File.open(procfile, "a") { |f| f.puts(line) }
          else
            File.write(procfile, "web: bin/rails server\n#{line}\n")
          end
        end

        def update_layout(context)
          layout = File.join(context.app_path, "app/views/layouts/application.html.erb")
          return unless File.exist?(layout)

          content = File.read(layout)
          return if content.include?('stylesheet_link_tag "tailwind"')

          tag = '    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>'
          content = content.sub(/\s*<\/head>/, "\n#{tag}\n  </head>")

          File.write(layout, content)
        end
      end
    end
  end
end
