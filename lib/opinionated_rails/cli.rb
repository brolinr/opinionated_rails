# frozen_string_literal: true

require "thor"

module OpinionatedRails
  class CLI < Thor
    class UnknownStepError < Thor::Error; end

    def self.exit_on_failure? = true

    # The database steps use the adapter name (:mysql2), but `rails new --database` wants "mysql".
    RAILS_DATABASE_FLAGS = { sqlite3: "sqlite3", postgresql: "postgresql", mysql2: "mysql" }.freeze

    # Steps `new` runs after `rails new`, in declaration order (StepGraph sorts by dependency).
    def self.generated_steps
      [
          Steps::Core::TestingStep,
          Steps::Core::FrontendStep,
          Steps::Core::DatabaseStep,
          Steps::Addons::JsLintStep,
          Steps::Addons::DocsStep,
          Steps::Addons::SpaControllerStep,
          Steps::Addons::TailwindStep,
          Steps::Addons::FactoryOrFixturesStep,
          Steps::Addons::VcrStep,
          Steps::Addons::RubocopStep,
          Steps::Addons::CiStep,
          Steps::Addons::FakerStep,
          Steps::Addons::PrIssueTemplatesStep,
          Steps::Addons::SolidStackStep,
          Steps::Addons::PaginationStep,
          Steps::Addons::StagingEnvStep,
          Steps::Addons::ServicesStep,
          Steps::Addons::SecretsHandlingStep,
          Steps::Addons::AuthStep,
          Steps::Addons::MailerStep,
          Steps::Addons::DockerKamalStep
      ]
    end

    desc "new [APP_NAME]", "Generate a new Rails app"
    method_option :skip_bundle_install, type: :boolean, default: false, desc: "Skip bundle install"
    method_option :database, aliases: "-d", type: :string, desc: "sqlite3, postgresql or mysql (skips the prompt)"
    method_option :javascript, aliases: "-j", type: :string,
                               desc: "Use React with this bundler: esbuild, bun or webpack (skips the prompts)"
    method_option :config, aliases: "-c", type: :string, desc: "YAML file of answers; see the README for keys"
    method_option :yes, aliases: "-y", type: :boolean, default: false, desc: "Accept the default for every unanswered prompt"
    def new(app_name = nil)
      RailsVersionGuard.check_installed!
      answers = preset_answers(app_name)
      shell = AnswerShell.new(Thor::Shell::Basic.new, answers: answers, yes: options[:yes])
      context = OpinionatedRails::Context.new(
        app_path: Dir.pwd,
        shell: shell,
        skip_bundle_install: options[:skip_bundle_install]
      )

      context.answer(:app_name_input, app_name) if app_name
      prompt_and_generate(context, Steps::Core::AppNameStep)
      chosen_name = context.output(:app_name, :app_name)
      if chosen_name && File.exist?(File.join(Dir.pwd, chosen_name))
        raise OpinionatedRails::Error, "Directory #{chosen_name} already exists"
      end
      prompt_and_generate(context, Steps::Core::DatabaseStep)
      prompt_and_generate(context, Steps::Core::AppTypeStep)

      testing_step = Steps::Core::TestingStep.new
      testing_step.prompt(context) if testing_step.if_condition(context)

      frontend_step = Steps::Core::FrontendStep.new
      frontend_step.prompt(context) if frontend_step.if_condition(context)

      app_name = context.output(:app_name, :app_name)
      raise OpinionatedRails::Error, "No app name captured" unless app_name

      Prerequisites.check!(context)

      flags = build_rails_new_flags(context)
      context.app_path = File.join(Dir.pwd, app_name)

      OpinionatedRails::Generators::RailsNewInvoker.new(
        app_name,
        flags: flags,
        skip_bundle_install: context.skip_bundle_install
      ).invoke

      prompted = [ :testing, :frontend, :database ]
      selected_steps = self.class.generated_steps.map(&:new)

      StepGraph.new(selected_steps).sorted.each do |step|
        run_step(context, step, prompted)
      end

      finish_app(context)

      unused = shell.unused_keys
      shell.say("Ignored options (their prompt did not apply): #{unused.join(', ')}", :yellow) unless unused.empty?
    end

    desc "add STEP_ID", "Add a step to an existing app"
    def add(_step_id)
      raise NotImplementedError, "OpinionatedRails::CLI#add not yet implemented"
    end

    desc "list", "List all supported steps"
    method_option :tier, type: :string, enum: %w[ core addon ], desc: "Filter by tier"
    def list
      steps = step_classes
      steps = steps.select { |step_class| step_class.tier.to_s == options[:tier] } if options[:tier]

      steps.each do |step_class|
        puts "#{step_class.id} (#{step_class.tier}) — #{step_class.summary}"
      end
    end

    desc "info STEP_ID", "Show details for a step"
    def info(step_id)
      step_id = step_id.to_sym
      step_class = step_classes.find { |klass| klass.id == step_id }
      raise UnknownStepError, "Unknown step: #{step_id.inspect}" unless step_class

      puts "id:          #{step_class.id}"
      puts "tier:        #{step_class.tier}"
      puts "summary:     #{step_class.summary}"
      puts "description: #{step_class.description}"
      puts "needs:       #{format_needs(step_class)}"
      puts "prompts for: #{format_prompts(step_class)}"
      puts "outputs:     #{safe_outputs(step_class)}"
    end

    private

    def run_step(context, step, prompted)
      unless prompted.include?(step.class.id)
        step.prompt(context) if step.if_condition(context)
        prompted << step.class.id
      end

      step.generate(context)
    rescue StandardError => e
      raise_with_recovery_hint(context, step.class.id, e)
    end

    def finish_app(context)
      { "bundle install" => -> { install_bundle(context) },
        "JavaScript install" => -> { install_javascript_packages(context) },
        "Tailwind build" => -> { build_tailwind_css(context) },
        "RuboCop autocorrect" => -> { autocorrect_style(context) } }.each do |name, action|
        action.call
      rescue StandardError => e
        raise_with_recovery_hint(context, name, e)
      end
    end

    # A failure after `rails new` leaves a half-built app. Say which step failed and where it is,
    # rather than leaving the user with only the underlying error.
    def raise_with_recovery_hint(context, step_name, error)
      raise OpinionatedRails::Error,
            "Step `#{step_name}` failed: #{error.message}\n" \
            "The partially generated app is in #{context.app_path}. Fix the problem above, then delete " \
            "that directory and run the command again (re-running over it is not supported)."
    end

    # Answers from --config, overridden by --database / --javascript. The APP_NAME argument wins
    # over a config app_name.
    def preset_answers(app_name)
      answers = load_config(options[:config])
      answers.delete("app_name") if app_name
      answers["database"] = options[:database] if options[:database]

      if options[:javascript]
        answers["frontend"] = "react"
        answers["bundler"] = options[:javascript]
      end

      answers
    end

    def load_config(path)
      return {} unless path

      raise OpinionatedRails::Error, "Config file not found: #{path}" unless File.file?(path)

      data = YAML.safe_load_file(path) || {}
      raise OpinionatedRails::Error, "Config file must be a YAML mapping of answers: #{path}" unless data.is_a?(Hash)

      data.transform_keys(&:to_s)
    rescue Psych::SyntaxError => e
      raise OpinionatedRails::Error, "Config file is not valid YAML (#{path}): #{e.message}"
    end

    # Steps append gems to the Gemfile after the last mid-run `bundle install`,
    # so resolve and install them once everything has been generated.
    def install_bundle(context)
      return if context.skip_bundle_install

      success = Dir.chdir(context.app_path) do
        Bundler.with_unbundled_env { system("bundle", "install", "--quiet") }
      end
      success || raise(OpinionatedRails::Error, "final bundle install failed")
    end

    # Steps add React, ESLint and Tailwind to package.json after jsbundling's own install ran, so
    # install them, then run the build scripts: without the built assets the first page load fails
    # with a missing-asset error, and a broken JS pipeline should surface here, not later.
    def install_javascript_packages(context)
      return if context.skip_bundle_install
      return unless File.exist?(File.join(context.app_path, "package.json"))

      runner = context.get(:bundler) == :bun ? "bun" : "yarn"
      unless Prerequisites.available?(runner)
        context.shell.say("Warning: #{runner} not found; run `#{runner} install` and its build scripts in the app.", :yellow)
        return
      end

      scripts = JSON.parse(File.read(File.join(context.app_path, "package.json"))).fetch("scripts", {})
      commands = [ [ runner, "install" ] ] + %w[ build build:css ].select { |name| scripts.key?(name) }.map { |name| [ runner, "run", name ] }

      commands.each do |command|
        success = Dir.chdir(context.app_path) { Bundler.with_unbundled_env { system(*command) } }
        success || raise(OpinionatedRails::Error, "#{command.join(' ')} failed")
      end
    end

    # tailwindcss-rails only builds the CSS through rake hooks, so a fresh app's first `bin/rails test`
    # (which renders the layout) fails on the missing tailwind.css until it has been built once.
    def build_tailwind_css(context)
      return if context.skip_bundle_install

      gemfile = File.join(context.app_path, "Gemfile")
      return unless File.exist?(gemfile) && File.read(gemfile).include?("tailwindcss-rails")

      success = Dir.chdir(context.app_path) { Bundler.with_unbundled_env { system("bin/rails", "tailwindcss:build") } }
      success || raise(OpinionatedRails::Error, "bin/rails tailwindcss:build failed")
    end

    # Generators we don't own (Devise, dockerfile-rails, ...) emit code that fails the app's own
    # RuboCop config, which would turn the generated CI red on the first push.
    def autocorrect_style(context)
      return if context.skip_bundle_install
      return unless File.exist?(File.join(context.app_path, "bin/rubocop"))

      clean = Dir.chdir(context.app_path) do
        Bundler.with_unbundled_env { system("bin/rubocop", "-a", "--format", "quiet") }
      end
      return if clean

      context.shell.say("Warning: bin/rubocop still reports offenses in the generated app; run it to review.", :yellow)
    end

    def prompt_and_generate(context, step_class)
      step = step_class.new
      step.prompt(context)
      step.generate(context)
    end

    def build_rails_new_flags(context)
      flags = []
      database = context.output(:database, :database)
      flags << "--database=#{RAILS_DATABASE_FLAGS.fetch(database, database)}"
      flags << "--api" if context.output(:app_type, :app_type) == :api_only
      flags << "--skip-test" if context.get(:testing) == :rspec
      flags << "--javascript=#{context.get(:bundler)}" if context.get(:frontend) == :react && context.get(:bundler)
      flags << "--skip-docker"
      flags << "--skip-kamal"
      flags << "--skip-ci"
      flags
    end

    def step_classes
      OpinionatedRails.step_classes
    end

    def format_needs(step_class)
      return "none" if step_class.needs.empty?

      step_class.needs.join(", ")
    end

    def format_prompts(step_class)
      step_class.respond_to?(:prompts) ? step_class.prompts : "not yet implemented"
    end

    def safe_outputs(step_class)
      step = step_class.new
      step.outputs(OpinionatedRails::Context.new(app_path: Dir.pwd))
    rescue NotImplementedError
      "not yet implemented"
    end
  end
end
