# frozen_string_literal: true

module OpinionatedRails
  module Generators
    class RailsNewInvoker
      def initialize(app_name, flags: [])
        @app_name = app_name
        @flags = flags
      end

      def invoke
        raise NotImplementedError, "OpinionatedRails::Generators::RailsNewInvoker#invoke not yet implemented"
      end
    end
  end
end
