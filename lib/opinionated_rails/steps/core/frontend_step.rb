# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Core
      class FrontendStep < Step
        def self.id = :frontend
        def self.summary = "Choose the frontend stack"
        def self.description = "Prompts for Stimulus+Hotwire, React, or no frontend for API-only apps."
        def self.tier = :core
        def self.prompts = "Frontend: Stimulus+Hotwire (1) or React (2), default Stimulus; React also asks for a bundler"

        BUNDLERS = %w[esbuild bun rollup webpack].freeze

        FRONTEND_OPTIONS = %w[stimulus react].freeze

        def if_condition(context)
          context.output(:app_type, :app_type) != :api_only
        end

        def prompt(context)
          shell = context.shell
          shell.say("Choose a frontend stack:")
          shell.say("  1. Stimulus + Hotwire (default)")
          shell.say("  2. React")

          choice = shell.ask("Frontend (default: Stimulus):").to_s.strip
          choice = "1" if choice.empty?

          loop do
            case choice.downcase
            when "stimulus", "stimulus+hotwire", "1"
              context.answer(:frontend, :stimulus_hotwire)
              break
            when "react", "2"
              context.answer(:frontend, :react)
              break
            else
              shell.say("Invalid. Enter 'Stimulus' or 'React', 1, or 2.", :red)
              choice = shell.ask("Frontend (default: Stimulus):").to_s.strip
            end
          end

          return unless context.get(:frontend) == :react

          prompt_bundler(context)
        end

        def generate(context)
          type = if if_condition(context)
                   context.get(:frontend) || :none
          else
                   :none
          end

          data = { frontend: type }
          data[:bundler] = context.get(:bundler) if type == :react

          context.set_output(:frontend, data)

          return if type == :none

          install_react(context) if type == :react
        end

        def outputs(context)
          context.output(:frontend)
        end

        private

        def prompt_bundler(context)
          shell = context.shell
          shell.say("Choose a JavaScript bundler:")
          BUNDLERS.each_with_index do |name, index|
            shell.say("  #{index + 1}. #{name.capitalize}")
          end

          choice = shell.ask("Bundler (default: esbuild):").to_s.strip
          choice = "esbuild" if choice.empty?

          loop do
            choice = BUNDLERS[choice.to_i - 1] if %w[1 2 3 4].include?(choice)

            if BUNDLERS.include?(choice.downcase)
              context.answer(:bundler, choice.downcase.to_sym)
              break
            end

            shell.say("Invalid. Enter #{BUNDLERS.join(', ')}.", :red)
            choice = shell.ask("Bundler (default: esbuild):").to_s.strip
          end
        end

        def install_react(context)
          bundler = context.output(:frontend, :bundler)

          update_package_json(context, bundler)
          add_esbuild_alias(context) if bundler == :esbuild
          warn_non_esbuild_alias(context, bundler) if bundler != :esbuild
          write_js_files(context)
          write_jsconfig(context)
          create_images_dir(context)
        end

        def update_package_json(context, bundler)
          package_json_path = File.join(context.app_path, "package.json")
          package = if File.exist?(package_json_path)
                      JSON.parse(File.read(package_json_path))
          else
                      { "scripts" => {}, "dependencies" => {} }
          end

          package["dependencies"] ||= {}
          package["dependencies"]["react"] = "18.2.0"
          package["dependencies"]["react-dom"] = "18.2.0"
          package["dependencies"]["react-router-dom"] = "6.23.1"

          if bundler == :esbuild && package["scripts"]["build"].nil?
            package["scripts"]["build"] = "esbuild app/javascript/*.* --bundle --sourcemap --outdir=app/assets/builds --public-path=assets"
          end

          File.write(package_json_path, JSON.pretty_generate(package))
        end

        def add_esbuild_alias(context)
          package_json_path = File.join(context.app_path, "package.json")
          package = JSON.parse(File.read(package_json_path))
          package["scripts"] ||= {}
          build = package["scripts"]["build"]

          if build && !build.include?("--alias:@=app/javascript")
            package["scripts"]["build"] = "#{build} --alias:@=app/javascript"
          end

          File.write(package_json_path, JSON.pretty_generate(package))
        end

        def warn_non_esbuild_alias(context, bundler)
          context.shell.say(
            "Warning: the @ import alias is configured for editor/TypeScript tooling only and won't resolve " \
            "at build time until a bundler-specific config is added (current bundler: #{bundler}).",
            :yellow
          )
        end

        def write_js_files(context)
          application_js = File.join(context.app_path, "app/javascript/application.js")
          File.delete(application_js) if File.exist?(application_js)

          FileUtils.mkdir_p(File.join(context.app_path, "app/javascript"))

          File.write(
            File.join(context.app_path, "app/javascript/application.jsx"),
            <<~'JS'
              import React from "react";
              import { createRoot } from "react-dom/client";
              import { RouterProvider } from "react-router-dom";
              import router from "./router";

              const root = createRoot(document.getElementById("root"));
              root.render(<RouterProvider router={router} />);
            JS
          )

          File.write(
            File.join(context.app_path, "app/javascript/router.jsx"),
            <<~'JS'
              import { createBrowserRouter } from "react-router-dom";

              const router = createBrowserRouter([
                { path: "/", element: <h1>Welcome</h1> }
              ]);

              export default router;
            JS
          )
        end

        def write_jsconfig(context)
          jsconfig = {
            "compilerOptions" => {
              "baseUrl" => ".",
              "paths" => {
                "@/*" => [ "app/javascript/*" ]
              }
            }
          }
          File.write(File.join(context.app_path, "jsconfig.json"), JSON.pretty_generate(jsconfig))
        end

        def create_images_dir(context)
          FileUtils.mkdir_p(File.join(context.app_path, "app/javascript/images"))
        end
      end
    end
  end
end
