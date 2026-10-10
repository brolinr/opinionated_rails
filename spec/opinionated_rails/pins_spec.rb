# frozen_string_literal: true

require "spec_helper"
require "opinionated_rails/pins"

RSpec.describe OpinionatedRails::Pins do
  let(:pins) { described_class.collect }

  it "finds every pinned gem and npm package in the steps" do
    names = pins.map(&:name)

    expect(names).to include("pagy", "devise", "sidekiq", "kamal", "dockerfile-rails", "rspec-rails")
    expect(names).to include("react", "react-dom", "eslint", "tailwindcss")
    expect(pins.map(&:registry).uniq).to contain_exactly(:gem, :npm)
  end

  it "has a registry name for every *_VERSION constant (a new pin cannot go unchecked)" do
    expect { pins }.not_to raise_error
    constants = Dir.glob(File.join(__dir__, "../../lib/opinionated_rails/steps/**/*.rb")).sum do |file|
      File.read(file, encoding: "UTF-8").scan(described_class::CONSTANT_PATTERN).size
    end

    expect(pins.count { |pin| pin.source.include?("steps") }).to be >= constants
  end

  it "fails loudly for a constant it does not know" do
    expect { described_class.pin_for_constant("MYSTERY", "1.0.0", "x.rb") }
      .to raise_error(ArgumentError, /No gem name for MYSTERY_VERSION/)
  end

  describe ".check" do
    let(:pin) { described_class::Pin.new(:gem, "pagy", "43.6.1", "x") }

    def check_with(info) = described_class.check([ pin ], fetcher: ->(*) { info }).first

    it "reports a pin that exists and is the latest as current" do
      expect(check_with({ versions: %w[ 43.6.0 43.6.1 ], latest: "43.6.1" }).status).to eq(:current)
    end

    it "reports a newer release as outdated" do
      result = check_with({ versions: %w[ 43.6.1 44.0.0 ], latest: "44.0.0" })

      expect(result.status).to eq(:outdated)
      expect(result.latest).to eq("44.0.0")
    end

    it "reports a pin that is not on the registry as missing" do
      expect(check_with({ versions: %w[ 43.6.0 ], latest: "43.6.0" }).status).to eq(:missing)
    end
  end
end
