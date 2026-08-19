# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::RubocopStep do
  it "has the expected id and tier" do
    expect(described_class.id).to eq(:rubocop)
    expect(described_class.tier).to eq(:addon)
  end

  it "raises NotImplementedError on generate" do
    step = described_class.new
    expect { step.generate(double("context")) }.to raise_error(
      NotImplementedError,
      /OpinionatedRails::Steps::Addons::RubocopStep#generate not yet implemented/
    )
  end
end
