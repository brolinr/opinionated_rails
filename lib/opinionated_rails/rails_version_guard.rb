# frozen_string_literal: true

module OpinionatedRails
  class RailsVersionGuard
    class UnsupportedError < OpinionatedRails::Error; end

    SUPPORTED_MAJOR_VERSIONS = [ 7, 8 ].freeze

    def self.from_string(version)
      new(version)
    end

    def initialize(version)
      @version = version
    end

    def assert!
      major = @version.to_s.split(".").first.to_i

      unless SUPPORTED_MAJOR_VERSIONS.include?(major)
        raise UnsupportedError, "Rails version #{@version} is not supported. Supported versions: #{SUPPORTED_MAJOR_VERSIONS.join(', ')}"
      end

      true
    end
  end
end
