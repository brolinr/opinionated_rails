# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class CiStep < Step
        def self.id = :ci
        def self.tier = :addon
        def self.needs = [ :rubocop, :testing ]
        def self.summary = "Configure CI"
        def self.description = "Generates GitHub Actions workflows for tests and RuboCop."
        def self.prompts = "Enable CI workflow? (default: yes)"

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          choice = shell.ask("Enable CI workflow? (default: yes):").to_s.strip
          choice = "yes" if choice.empty?

          loop do
            case choice.downcase
            when "yes", "y"
              context.answer(:ci, true)
              break
            when "no", "n"
              context.answer(:ci, false)
              break
            else
              shell.say("Invalid. Enter 'yes' or 'no'.", :red)
              choice = shell.ask("Enable CI workflow? (default: yes):").to_s.strip
            end
          end
        end

        def generate(context)
          enabled = context.get(:ci) != false

          write_workflow(context) if enabled

          context.set_output(:ci, { ci: enabled })
        end

        def outputs(context)
          context.output(:ci)
        end

        private

        def write_workflow(context)
          path = File.join(context.app_path, ".github/workflows/ci.yml")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, workflow_content(context))
        end

        def workflow_content(context)
          jobs = <<~YAML
            jobs:
              test:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@v4
                  - uses: ruby/setup-ruby@v1
                    with:
                      bundler-cache: true
                  - name: Run tests
                    run: #{test_command(context)}

              rubocop:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@v4
                  - uses: ruby/setup-ruby@v1
                    with:
                      bundler-cache: true
                  - name: Run RuboCop
                    run: bin/rubocop -f github
          YAML

          jobs += js_lint_job if context.output(:js_lint, :js_lint) || false

          <<~YAML
            name: CI

            on:
              push:
              pull_request:

            #{jobs}
          YAML
        end

        def test_command(context)
          if context.output(:testing, :test_framework) == :rspec
            "bundle exec rspec"
          else
            "bin/rails test"
          end
        end

        def js_lint_job
          <<~YAML

            \x20\x20js_lint:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@v4
                  - uses: actions/setup-node@v4
                  - run: npm install
                  - name: Run JS lint
                    run: npm run lint:js
          YAML
        end
      end
    end
  end
end
