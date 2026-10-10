# frozen_string_literal: true

require "open3"

module OpinionatedRails
  # The steps patch text and config that Rails 8.1 generates (Solid defaults, Kamal, authentication),
  # so only Rails 8.1+ within 8.x is supported. Other versions are rejected before anything is generated.
  class RailsVersionGuard
    class UnsupportedError < OpinionatedRails::Error; end

    MINIMUM = Gem::Version.new("8.1")
    SUPPORTED_MAJOR = 8

    def self.from_string(version)
      new(version)
    end

    # Version of the `rails` executable `rails new` will use, or an error if there is none.
    def self.installed
      output, status = Bundler.with_unbundled_env { Open3.capture2e("rails", "--version") }
      version = output[/Rails (\d[\w.]*)/, 1]
      return version if status.success? && version

      raise UnsupportedError, "Rails is not installed or `rails --version` failed. Install it with `gem install rails`."
    rescue Errno::ENOENT
      raise UnsupportedError, "Rails is not installed. Install it with `gem install rails`."
    end

    def self.check_installed!
      from_string(installed).assert!
    end

    def initialize(version)
      @version = version
    end

    def assert!
      parsed = Gem::Version.correct?(@version) && Gem::Version.new(@version)

      unless parsed && parsed.segments.first == SUPPORTED_MAJOR && parsed >= MINIMUM
        raise UnsupportedError,
              "Rails #{@version} is not supported. opinionated_rails needs Rails #{MINIMUM} or newer in the " \
              "#{SUPPORTED_MAJOR}.x series. Update with `gem update rails`."
      end

      true
    end
  end
end
