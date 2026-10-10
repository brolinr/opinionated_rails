# frozen_string_literal: true

require "thor"

module OpinionatedRails
  class CLI < Thor
    class UnknownStepError < Thor::Error; end

    def self.exit_on_failure? = true

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
    def new(app_name = nil)
      context = OpinionatedRails::Context.new(
        app_path: Dir.pwd,
        shell: Thor::Shell::Basic.new,
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
        unless prompted.include?(step.class.id)
          step.prompt(context) if step.if_condition(context)
          prompted << step.class.id
        end

        step.generate(context)
      end

      install_bundle(context)
      install_javascript_packages(context)
      autocorrect_style(context)
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

    # Steps append gems to the Gemfile after the last mid-run `bundle install`,
    # so resolve and install them once everything has been generated.
    def install_bundle(context)
      return if context.skip_bundle_install

      success = Dir.chdir(context.app_path) do
        Bundler.with_unbundled_env { system("bundle", "install", "--quiet") }
      end
      success || raise(OpinionatedRails::Error, "final bundle install failed")
    end

    # Steps add React, ESLint and Tailwind to package.json after jsbundling's own install ran,
    # so without this `yarn build` fails on a fresh app.
    def install_javascript_packages(context)
      return if context.skip_bundle_install
      return unless File.exist?(File.join(context.app_path, "package.json"))

      command = context.get(:bundler) == :bun ? %w[ bun install ] : %w[ yarn install ]
      unless Prerequisites.available?(command.first)
        context.shell.say("Warning: #{command.first} not found; run `#{command.join(' ')}` in the app.", :yellow)
        return
      end

      success = Dir.chdir(context.app_path) { Bundler.with_unbundled_env { system(*command) } }
      success || raise(OpinionatedRails::Error, "#{command.join(' ')} failed")
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
      flags << "--database=#{context.output(:database, :database)}"
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
