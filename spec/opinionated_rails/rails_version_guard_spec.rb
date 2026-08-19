# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::RailsVersionGuard do
  it "accepts Rails 7" do
    expect(described_class.from_string("7.1.0").assert!).to be true
  end

  it "accepts Rails 8" do
    expect(described_class.from_string("8.0.1").assert!).to be true
  end

  it "rejects Rails 6" do
    expect { described_class.from_string("6.1.0").assert! }.to raise_error(
      described_class::UnsupportedError,
      /Rails version 6.1.0 is not supported/
    )
  end

  it "rejects Rails 9" do
    expect { described_class.from_string("9.0.0.beta").assert! }.to raise_error(
      described_class::UnsupportedError,
      /Rails version 9.0.0.beta is not supported/
    )
  end
end
