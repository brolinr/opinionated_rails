# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class AuthStep < Step
        def self.id = :auth
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Configure authentication"
        def self.description = "Prompts for a user model name and chooses Rails 8 built-in, Devise, or none."
        def self.prompts = "User model name (default: User), then Rails 8 built-in / Devise / None (default: None)"

        MODEL_NAME_FORMAT = /\A[A-Z][A-Za-z0-9]*\z/
        DEVISE_VERSION = "5.0.4".freeze

        def if_condition(_context) = true

        API_ONLY_NOTICE = "Authentication is skipped for API-only apps: Rails' built-in generator and Devise " \
                          "both generate browser-session code that does not work without cookies and views."

        def prompt(context)
          shell = context.shell

          if api_only?(context)
            shell.say(API_ONLY_NOTICE, :yellow)
            context.answer(:auth, :none)
            return
          end

          model_name = shell.ask("User model name (default: User):").to_s.strip
          model_name = "User" if model_name.empty?
          until MODEL_NAME_FORMAT.match?(model_name)
            shell.say("Invalid model name. Use a CamelCase constant such as User or Account.", :red)
            model_name = shell.ask("User model name (default: User):").to_s.strip
            model_name = "User" if model_name.empty?
          end
          context.answer(:auth_model_name, model_name)

          shell.say("Choose an authentication strategy:")
          shell.say("  1. None (default)")
          shell.say("  2. Rails 8 built-in")
          shell.say("  3. Devise")

          choice = shell.ask("Authentication (default: None):").to_s.strip
          choice = "1" if choice.empty?

          loop do
            case choice.downcase
            when "none", "1"
              context.answer(:auth, :none)
              break
            when "rails8", "rails 8", "2"
              context.answer(:auth, :rails8)
              break
            when "devise", "3"
              context.answer(:auth, :devise)
              break
            else
              shell.say("Invalid. Enter 'None', 'Rails8', 'Devise', 1, 2, or 3.", :red)
              choice = shell.ask("Authentication (default: None):").to_s.strip
              choice = "1" if choice.empty?
            end
          end
        end

        def generate(context)
          strategy = api_only?(context) ? :none : (context.get(:auth) || :none)

          case strategy
          when :rails8
            install_rails8_auth(context)
          when :devise
            install_devise(context)
          else
            context.set_output(:auth, { auth: :none })
          end
        end

        def outputs(context)
          context.output(:auth)
        end

        private

        def api_only?(context) = context.output(:app_type, :app_type) == :api_only

        def install_rails8_auth(context)
          unless context.skip_bundle_install
            command = [ "bundle", "exec", "rails", "generate", "authentication" ]

            run_in_app(context, "bundle", "install", "--quiet") ||
              raise(OpinionatedRails::Error, "bundle install failed")
            run_in_app(context, *command) ||
              raise(OpinionatedRails::Error, "rails generate authentication failed")
          end

          add_home_page(context) unless context.output(:frontend, :frontend) == :react

          context.set_output(:auth, { auth: :rails8, user_model: "User" })
        end

        # Rails 8's generated SessionsController redirects to root_url after sign-in, but a new app has no
        # root route, so signing in would raise NameError. (React apps get their root from the SPA step.)
        def add_home_page(context)
          routes_path = File.join(context.app_path, "config/routes.rb")
          return unless File.exist?(routes_path)

          routes = File.readlines(routes_path)
          return if routes.any? { |line| line.match?(/^\s*root\b/) }

          end_index = routes.rindex { |line| line.strip == "end" }
          return unless end_index

          routes.insert(end_index, "  root \"home#index\"\n")
          File.write(routes_path, routes.join)

          write_file(context, "app/controllers/home_controller.rb", "class HomeController < ApplicationController\n  def index\n  end\nend\n")
          write_file(context, "app/views/home/index.html.erb", "<h1>Home</h1>\n")
        end

        def write_file(context, relative, content)
          path = File.join(context.app_path, relative)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content) unless File.exist?(path)
        end

        def install_devise(context)
          model_name = context.get(:auth_model_name) || "User"

          add_top_level_gem(context, "gem \"devise\", \"#{DEVISE_VERSION}\"")

          unless context.skip_bundle_install
            run_in_app(context, "bundle", "install", "--quiet") ||
              raise(OpinionatedRails::Error, "bundle install failed")
            run_in_app(context, "bundle", "exec", "rails", "generate", "devise:install") ||
              raise(OpinionatedRails::Error, "devise:install failed")
            run_in_app(context, "bundle", "exec", "rails", "generate", "devise", model_name) ||
              raise(OpinionatedRails::Error, "devise generator failed")

            run_in_app(context, "bundle", "exec", "rails", "generate", "devise:views") ||
              raise(OpinionatedRails::Error, "devise:views failed")
          end

          context.set_output(:auth, { auth: :devise, user_model: model_name })
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
      end
    end
  end
end
