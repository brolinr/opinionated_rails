# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class SpaControllerStep < Step
        def self.id = :spa_controller
        def self.tier = :addon
        def self.needs = [ :frontend ]
        def self.summary = "Add a SPA catch-all controller"
        def self.description = "Generates the always-present spa_controller.rb#root action."
        def self.prompts = "None"

        def if_condition(context)
          context.output(:app_type, :app_type) != :api_only
        end

        def prompt(_context); end

        def generate(context)
          unless if_condition(context)
            context.set_output(:spa_controller, nil)
            return
          end

          write_controller(context)
          write_view(context)
          append_route(context)

          output_key = context.output(:frontend, :frontend) == :react ? :react_mount : :fallback_404
          context.set_output(:spa_controller, { spa_controller: output_key })
        end

        def outputs(context)
          context.output(:spa_controller)
        end

        private

        def write_controller(context)
          controller_path = File.join(context.app_path, "app/controllers/spa_controller.rb")
          FileUtils.mkdir_p(File.dirname(controller_path))

          controller = if context.output(:frontend, :frontend) == :react
                         "class SpaController < ApplicationController\n  def root\n  end\nend\n"
          else
                         "class SpaController < ApplicationController\n  def root\n    render status: :not_found\n  end\nend\n"
          end

          File.write(controller_path, controller)
        end

        def write_view(context)
          view_dir = File.join(context.app_path, "app/views/spa")
          FileUtils.mkdir_p(view_dir)

          view = if context.output(:frontend, :frontend) == :react
                   "<div id=\"root\"></div>\n"
          else
                   "<h1>Not Found</h1>\n"
          end

          File.write(File.join(view_dir, "root.html.erb"), view)
        end

        def append_route(context)
          routes_path = File.join(context.app_path, "config/routes.rb")
          return unless File.exist?(routes_path)

          lines = File.readlines(routes_path)
          return if lines.any? { |line| line.include?("spa#root") }

          end_index = lines.rindex { |line| line.strip == "end" }
          return unless end_index

          # `*path` does not match "/", so a React app needs an explicit root.
          routes = []
          routes << "  root \"spa#root\"\n" if context.output(:frontend, :frontend) == :react
          routes << "  get \"*path\", to: \"spa#root\", constraints: ->(req) { !req.xhr? && req.format.html? }\n"
          lines.insert(end_index, *routes)

          File.write(routes_path, lines.join)
        end
      end
    end
  end
end
