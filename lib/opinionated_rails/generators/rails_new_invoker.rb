# frozen_string_literal: true

module OpinionatedRails
  module Generators
    class RailsNewInvoker
      def initialize(app_name, flags: [], skip_bundle_install: false)
        @app_name = app_name
        @flags = flags
        @skip_bundle_install = skip_bundle_install
      end

      def invoke
        command = [ "rails", "new", @app_name, *@flags ]
        command << "--skip-bundle" if @skip_bundle_install

        success = if defined?(Bundler)
                    Bundler.with_unbundled_env { system(*command) }
        else
                    system(*command)
        end

        success || raise(OpinionatedRails::Error, "rails new failed")
      end
    end
  end
end
