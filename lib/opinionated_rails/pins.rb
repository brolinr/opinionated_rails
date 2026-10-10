# frozen_string_literal: true

require "json"
require "net/http"

module OpinionatedRails
  # Every gem and npm package the steps pin. `rake pins:check` confirms each pinned version still
  # exists on its registry and reports newer ones, so pins cannot rot unnoticed.
  module Pins
    Pin = Struct.new(:registry, :name, :version, :source)
    Result = Struct.new(:pin, :status, :latest)

    # *_VERSION constants in the steps => gem name (the constant name alone is ambiguous)
    GEM_NAMES = {
      "RSPEC" => "rspec-rails", "REDIS" => "redis", "SIDEKIQ" => "sidekiq", "FACTORY_BOT" => "factory_bot_rails",
      "DEVISE" => "devise", "GEARED_PAGINATION" => "geared_pagination", "PAGY" => "pagy",
      "RUBOCOP_OMAKASE" => "rubocop-rails-omakase", "DOTENV_RAILS" => "dotenv-rails", "VCR" => "vcr",
      "WEBMOCK" => "webmock", "DOCKERFILE_RAILS" => "dockerfile-rails", "KAMAL" => "kamal",
      "LETTER_OPENER" => "letter_opener", "POSTMARK_RAILS" => "postmark-rails", "FAKER" => "faker",
      "TAILWIND_RAILS" => "tailwindcss-rails"
    }.freeze

    # constants that pin an npm package rather than a gem
    NPM_CONSTANTS = { "TAILWIND" => "tailwindcss" }.freeze

    CONSTANT_PATTERN = /^\s+([A-Z][A-Z_]*)_VERSION = "(\d[\w.]*)"/
    NPM_ASSIGNMENT_PATTERN = /package\["(?:dependencies|devDependencies)"\]\["([^"]+)"\] = "(\d[\w.]*)"/

    def self.collect(root = File.expand_path("..", __dir__))
      Dir.glob(File.join(root, "opinionated_rails/steps/**/*.rb")).sort.flat_map do |file|
        source = File.read(file, encoding: "UTF-8")
        relative = file.sub("#{root}/", "")
        constants = source.scan(CONSTANT_PATTERN).map { |const, version| pin_for_constant(const, version, relative) }
        npm = source.scan(NPM_ASSIGNMENT_PATTERN).map { |name, version| Pin.new(:npm, name, version, relative) }
        constants + npm
      end.uniq { |pin| [ pin.registry, pin.name, pin.version ] }
    end

    def self.pin_for_constant(const, version, source)
      return Pin.new(:npm, NPM_CONSTANTS.fetch(const), version, source) if NPM_CONSTANTS.key?(const)

      Pin.new(:gem, GEM_NAMES.fetch(const) { raise ArgumentError, "No gem name for #{const}_VERSION in #{source}; add it to Pins::GEM_NAMES" },
              version, source)
    end

    # fetcher: ->(registry, name) { { versions: [...], latest: "x" } }
    def self.check(pins, fetcher: method(:fetch))
      pins.map do |pin|
        info = fetcher.call(pin.registry, pin.name)
        Result.new(pin, status_for(pin, info), info[:latest])
      end
    end

    def self.status_for(pin, info)
      return :missing unless info[:versions].include?(pin.version)

      newer?(info[:latest], pin.version) ? :outdated : :current
    end

    def self.newer?(latest, pinned)
      Gem::Version.correct?(latest) && Gem::Version.correct?(pinned) && Gem::Version.new(latest) > Gem::Version.new(pinned)
    end

    def self.fetch(registry, name)
      case registry
      when :gem
        list = JSON.parse(get("https://rubygems.org/api/v1/versions/#{name}.json"))
        stable = list.reject { |v| v["prerelease"] }.map { |v| v["number"] }
        { versions: list.map { |v| v["number"] }, latest: stable.max_by { |v| Gem::Version.new(v) } }
      when :npm
        data = JSON.parse(get("https://registry.npmjs.org/#{name}"))
        { versions: data.fetch("versions").keys, latest: data.dig("dist-tags", "latest") }
      end
    end

    def self.get(url)
      response = Net::HTTP.get_response(URI(url))
      raise "GET #{url} returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end
  end
end
