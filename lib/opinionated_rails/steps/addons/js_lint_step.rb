# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class JsLintStep < Step
        def self.id = :js_lint
        def self.tier = :addon
        def self.needs = [ :frontend ]
        def self.summary = "Configure JavaScript linting"
        def self.description = "Installs ESLint and writes an ESLint 9 flat config (eslint.config.js) for the chosen frontend stack."
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
              choice = "yes" if choice.empty?
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

        # ESLint 9 flat config. `files` names .jsx explicitly: ESLint lints only .js unless told otherwise,
        # which previously left every React component unlinted.
        PLAIN_ESLINT_CONFIG = <<~JS
          const js = require("@eslint/js")
          const globals = require("globals")

          module.exports = [
            { ignores: ["app/assets/builds/**", "node_modules/**"] },
            js.configs.recommended,
            {
              files: ["**/*.js"],
              languageOptions: {
                ecmaVersion: "latest",
                sourceType: "module",
                globals: { ...globals.browser }
              }
            }
          ]
        JS

        REACT_ESLINT_CONFIG = <<~JS
          const js = require("@eslint/js")
          const globals = require("globals")
          const react = require("eslint-plugin-react")
          const reactHooks = require("eslint-plugin-react-hooks")

          module.exports = [
            { ignores: ["app/assets/builds/**", "node_modules/**"] },
            js.configs.recommended,
            { ...react.configs.flat.recommended, files: ["**/*.{js,jsx}"] },
            reactHooks.configs.flat.recommended,
            {
              files: ["**/*.{js,jsx}"],
              languageOptions: {
                ecmaVersion: "latest",
                sourceType: "module",
                globals: { ...globals.browser }
              },
              settings: { react: { version: "detect" } }
            }
          ]
        JS

        def write_eslint_config(context)
          react = context.output(:frontend, :frontend) == :react
          File.write(File.join(context.app_path, "eslint.config.js"), react ? REACT_ESLINT_CONFIG : PLAIN_ESLINT_CONFIG)
          FileUtils.rm_f(File.join(context.app_path, ".eslintrc.json")) # ESLint 8 format, ignored by ESLint 9
        end

        def update_package_json(context)
          package_json_path = File.join(context.app_path, "package.json")
          package = File.exist?(package_json_path) ? JSON.parse(File.read(package_json_path)) : {}
          package["scripts"] ||= {}
          package["scripts"]["lint:js"] = "eslint app/javascript"
          package["devDependencies"] ||= {}
          package["devDependencies"]["eslint"] = "9.39.5"
          package["devDependencies"]["@eslint/js"] = "9.39.5"
          package["devDependencies"]["globals"] = "17.13.0"

          if context.output(:frontend, :frontend) == :react
            package["devDependencies"]["eslint-plugin-react"] = "7.37.5"
            package["devDependencies"]["eslint-plugin-react-hooks"] = "7.1.1"
          end

          File.write(package_json_path, JSON.pretty_generate(package))
        end
      end
    end
  end
end
