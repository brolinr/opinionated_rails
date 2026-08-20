# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class VcrStep < Step
        def self.id = :vcr
        def self.tier = :addon
        def self.needs = [ :testing ]
        def self.summary = "Configure VCR"
        def self.description = "Installs VCR for recording and replaying HTTP interactions in tests."
        def self.prompts = "Enable VCR for HTTP interaction recording? (default: no)"

        VCR_VERSION = "6.2.0".freeze
        WEBMOCK_VERSION = "3.23.1".freeze

        MINIMAL_RAILS_HELPER = <<~RUBY
          require 'spec_helper'
          ENV['RAILS_ENV'] ||= 'test'
          require_relative '../config/environment'
          require 'rspec/rails'

          RSpec.configure do |config|
            config.fixture_paths = [
              Rails.root.join('spec/fixtures')
            ]
            config.use_transactional_fixtures = true
          end
        RUBY

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          choice = shell.ask("Enable VCR for HTTP interaction recording? (default: no):").to_s.strip
          choice = "no" if choice.empty?

          loop do
            case choice.downcase
            when "yes", "y"
              context.answer(:vcr, true)
              break
            when "no", "n"
              context.answer(:vcr, false)
              break
            else
              shell.say("Invalid. Enter 'yes' or 'no'.", :red)
              choice = shell.ask("Enable VCR for HTTP interaction recording? (default: no):").to_s.strip
            end
          end
        end

        def generate(context)
          enabled = context.get(:vcr) == true

          unless enabled
            context.set_output(:vcr, { vcr: false })
            return
          end

          add_test_group_gems(context)

          if context.output(:testing, :test_framework) == :minitest
            install_for_minitest(context)
          else
            install_for_rspec(context)
          end

          context.set_output(:vcr, { vcr: true })
        end

        def outputs(context)
          context.output(:vcr)
        end

        private

        def add_test_group_gems(context)
          add_test_group_gem(context, "gem \"vcr\", \"#{VCR_VERSION}\"")
          add_test_group_gem(context, "gem \"webmock\", \"#{WEBMOCK_VERSION}\"")
        end

        def add_test_group_gem(context, gem_line)
          gemfile_path = File.join(context.app_path, "Gemfile")
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?(gem_line)

          lines = content.lines
          group_start = lines.index { |line| line.strip == "group :test do" }

          if group_start
            end_index = (group_start + 1...lines.size).find { |i| lines[i].strip == "end" }
            lines.insert(end_index, "  #{gem_line}\n")
          else
            lines << "\n" unless lines.last.nil? || lines.last.end_with?("\n")
            lines << "\ngroup :test do\n  #{gem_line}\nend\n"
          end

          File.write(gemfile_path, lines.join)
        end

        def vcr_config(cassette_dir)
          <<~RUBY
            require "vcr"
            require "webmock"

            VCR.configure do |config|
              config.cassette_library_dir = "#{cassette_dir}"
              config.hook_into :webmock

              # Redact secrets from recorded cassettes before they're written to disk.
              # Example: strip a bearer token from the Authorization header.
              config.filter_sensitive_data("<API_KEY>") { ENV["API_KEY"] }
            end
          RUBY
        end

        def install_for_rspec(context)
          support_path = File.join(context.app_path, "spec/support/vcr.rb")
          FileUtils.mkdir_p(File.dirname(support_path))
          File.write(support_path, vcr_config("spec/cassettes"))

          ensure_rails_helper(context)
          require_support_files(context)
        end

        def install_for_minitest(context)
          support_path = File.join(context.app_path, "test/support/vcr.rb")
          FileUtils.mkdir_p(File.dirname(support_path))
          File.write(support_path, vcr_config("test/cassettes"))

          require_line = "require_relative \"support/vcr\"\n"
          test_helper_path = File.join(context.app_path, "test/test_helper.rb")
          return unless File.exist?(test_helper_path)

          content = File.read(test_helper_path)
          return if content.include?(require_line)

          File.write(test_helper_path, "#{require_line}#{content}")
        end

        def ensure_rails_helper(context)
          rails_helper_path = File.join(context.app_path, "spec/rails_helper.rb")
          return if File.exist?(rails_helper_path)

          FileUtils.mkdir_p(File.dirname(rails_helper_path))
          File.write(rails_helper_path, MINIMAL_RAILS_HELPER)
        end

        def require_support_files(context)
          rails_helper_path = File.join(context.app_path, "spec/rails_helper.rb")
          require_line = "require \"support/vcr\"\n"

          content = File.read(rails_helper_path)
          return if content.include?(require_line) || content.include?("support/**/*.rb")

          lines = content.lines
          require_index = lines.rindex { |line| line.start_with?("require") }
          insert_at = require_index ? require_index + 1 : lines.size

          lines.insert(insert_at, require_line)
          File.write(rails_helper_path, lines.join)
        end
      end
    end
  end
end
