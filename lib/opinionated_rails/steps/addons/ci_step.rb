# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class CiStep < Step
        def self.id = :ci
        def self.tier = :addon
        def self.needs = [ :rubocop, :testing ]
        def self.summary = "Configure CI"
        def self.description = "Generates a GitHub Actions workflow for tests, RuboCop, security scans and JS lint."
        def self.prompts = "Enable CI workflow? (default: yes)"

        POSTGRES_SERVICE = <<~YAML.gsub(/^/, "      ")
          postgres:
            image: postgres:16
            env:
              POSTGRES_USER: postgres
              POSTGRES_PASSWORD: postgres
            ports: [ "5432:5432" ]
            options: >-
              --health-cmd="pg_isready" --health-interval=10s --health-timeout=5s --health-retries=5
        YAML

        MYSQL_SERVICE = <<~YAML.gsub(/^/, "      ")
          mysql:
            image: mysql:8.4
            env:
              MYSQL_ALLOW_EMPTY_PASSWORD: "true"
            ports: [ "3306:3306" ]
            options: >-
              --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=5
        YAML

        REDIS_SERVICE = <<~YAML.gsub(/^/, "      ")
          redis:
            image: redis:7
            ports: [ "6379:6379" ]
            options: >-
              --health-cmd="redis-cli ping" --health-interval=10s --health-timeout=5s --health-retries=5
        YAML

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
              choice = "yes" if choice.empty?
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
          jobs = [ security_job(context), test_job(context), rubocop_job ]
          jobs << js_lint_job if context.output(:js_lint, :js_lint) || false

          <<~YAML + jobs.compact.join("\n")
            name: CI

            on:
              pull_request:
              push:
                branches: [ main ]

            permissions:
              contents: read

            concurrency:
              group: ci-${{ github.workflow }}-${{ github.ref }}
              cancel-in-progress: true

            jobs:
          YAML
        end

        CHECKOUT_AND_RUBY = <<~YAML.gsub(/^/, "      ")
          - uses: actions/checkout@v4
          - uses: ruby/setup-ruby@v1
            with:
              bundler-cache: true
        YAML

        # `rails new --skip-ci` drops Rails' own scan job, so keep the same scans here.
        def security_job(context)
          scans = %w[ brakeman bundler-audit ].select { |tool| File.exist?(File.join(context.app_path, "bin", tool)) }
          return if scans.empty?

          steps = scans.map { |tool| "      - name: Run #{tool}\n        run: bin/#{tool}#{' --no-pager' if tool == 'brakeman'}\n" }

          <<~YAML.chomp + "\n" + CHECKOUT_AND_RUBY + steps.join
            \x20\x20security:
                runs-on: ubuntu-latest
                timeout-minutes: 15
                steps:
          YAML
        end

        def test_job(context)
          header = <<~YAML.chomp
            \x20\x20test:
                runs-on: ubuntu-latest
                timeout-minutes: 15
          YAML

          setup = []
          setup << "      - uses: actions/setup-node@v4\n        with:\n          node-version: lts/*\n" if react?(context)
          setup << "      - name: Install system libraries\n        run: sudo apt-get update && sudo apt-get install --no-install-recommends -y libmysqlclient-dev\n" if database(context) == :mysql2

          steps = CHECKOUT_AND_RUBY + setup.join
          steps += "      - run: npm install\n" if react?(context)
          # db:migrate (not db:test:prepare) because a fresh app has migrations but no schema.rb yet.
          # DATABASE_URL carries a database name: dockerfile-rails' database.yml appends "_cache" to its path.
          steps += "      - name: Set up database\n        run: bin/rails db:create db:migrate\n"
          steps += "      - name: Run tests\n        run: #{test_command(context)}\n"

          "#{header}\n#{services_and_env(context)}    steps:\n#{steps}"
        end

        def services_and_env(context)
          services = []
          env = [ "RAILS_ENV: test" ]

          case database(context)
          when :postgresql
            services << POSTGRES_SERVICE
            env << "DATABASE_URL: postgres://postgres:postgres@localhost:5432/ci_test"
          when :mysql2
            services << MYSQL_SERVICE
            env << "DATABASE_URL: mysql2://root@127.0.0.1:3306/ci_test"
          end

          if context.output(:solid_stack, :solid_stack) == :redis
            services << REDIS_SERVICE
            env << "REDIS_URL: redis://localhost:6379/1"
          end

          block = +""
          block << "    services:\n#{services.join}" unless services.empty?
          block << "    env:\n#{env.map { |line| "      #{line}\n" }.join}"
          block
        end

        def database(context) = context.output(:database, :database)

        def react?(context) = context.output(:frontend, :frontend) == :react

        def rubocop_job
          <<~YAML.chomp + "\n" + CHECKOUT_AND_RUBY + "      - name: Run RuboCop\n        run: bin/rubocop -f github\n"
            \x20\x20rubocop:
                runs-on: ubuntu-latest
                timeout-minutes: 15
                steps:
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
          <<~YAML.chomp + "\n"
            \x20\x20js_lint:
                runs-on: ubuntu-latest
                timeout-minutes: 15
                steps:
                  - uses: actions/checkout@v4
                  - uses: actions/setup-node@v4
                    with:
                      node-version: lts/*
                  - run: npm install
                  - name: Run JS lint
                    run: npm run lint:js
          YAML
        end
      end
    end
  end
end
