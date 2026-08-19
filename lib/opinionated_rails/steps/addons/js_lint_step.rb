# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class JsLintStep < Step
        def self.id = :js_lint
        def self.tier = :addon
        def self.needs = [ :frontend ]
        def self.summary = "Configure JavaScript linting"
        def self.description = "Installs ESLint and writes .eslintrc.json for the chosen frontend stack."
        def self.prompts = "Enable JS linting? (default: yes)"

        def if_condition(context)
          context.output(:frontend, :frontend) != :none
        end

        def prompt(context)
          shell = context.shell
          choice = shell.ask("Enable JS linting? (default: yes):").to_s.strip
          choice = "yes" if choice.empty?

          loop do
            case choice.downcase
            when "yes", "y"
              context.answer(:js_lint, true)
              break
            when "no", "n"
              context.answer(:js_lint, false)
              break
            else
              shell.say("Invalid. Enter 'yes' or 'no'.", :red)
              choice = shell.ask("Enable JS linting? (default: yes):").to_s.strip
            end
          end
        end

        def generate(context)
          enabled = if if_condition(context)
                      context.get(:js_lint) != false
          else
                      false
          end

          data = { js_lint: enabled }
          data[:js_lint_tool] = :eslint if enabled

          context.set_output(:js_lint, data)

          return unless enabled

          write_eslint_config(context)
          update_package_json(context)
        end

        def outputs(context)
          context.output(:js_lint)
        end

        private

        def write_eslint_config(context)
          config = if context.output(:frontend, :frontend) == :react
                     react_eslint_config
          else
                     plain_eslint_config
          end

          File.write(File.join(context.app_path, ".eslintrc.json"), JSON.pretty_generate(config))
        end

        def plain_eslint_config
          {
            "env" => { "browser" => true, "es2021" => true, "node" => true },
            "extends" => [ "eslint:recommended" ],
            "parserOptions" => { "ecmaVersion" => "latest", "sourceType" => "module" },
            "rules" => {}
          }
        end

        def react_eslint_config
          {
            "env" => { "browser" => true, "es2021" => true, "node" => true },
            "extends" => [
              "eslint:recommended",
              "plugin:react/recommended",
              "plugin:react-hooks/recommended"
            ],
            "parserOptions" => {
              "ecmaVersion" => "latest",
              "sourceType" => "module",
              "ecmaFeatures" => { "jsx" => true }
            },
            "plugins" => [ "react", "react-hooks" ],
            "settings" => { "react" => { "version" => "detect" } },
            "rules" => {}
          }
        end

        def update_package_json(context)
          package_json_path = File.join(context.app_path, "package.json")
          package = File.exist?(package_json_path) ? JSON.parse(File.read(package_json_path)) : {}
          package["scripts"] ||= {}
          package["scripts"]["lint:js"] = "eslint app/javascript"
          package["devDependencies"] ||= {}
          package["devDependencies"]["eslint"] = "8.57.0"

          if context.output(:frontend, :frontend) == :react
            package["devDependencies"]["eslint-plugin-react"] = "7.34.0"
            package["devDependencies"]["eslint-plugin-react-hooks"] = "4.6.0"
          end

          File.write(package_json_path, JSON.pretty_generate(package))
        end
      end
    end
  end
end
