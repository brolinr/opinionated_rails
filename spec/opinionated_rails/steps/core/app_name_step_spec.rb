# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Core::AppNameStep do
  it "has the expected id and tier" do
    expect(described_class.id).to eq(:app_name)
    expect(described_class.tier).to eq(:core)
  end

  it "raises NotImplementedError on generate" do
    step = described_class.new
    expect { step.generate(double("context")) }.to raise_error(
      NotImplementedError,
      /OpinionatedRails::Steps::Core::AppNameStep#generate not yet implemented/
    )
  end
end
