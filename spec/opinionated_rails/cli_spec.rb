# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::CLI do
  describe "list" do
    it "lists all registered steps" do
      expect { described_class.start([ "list" ]) }.to output(/app_name/).to_stdout
      expect { described_class.start([ "list" ]) }.to output(/rubocop/).to_stdout
    end

    it "filters by --tier core" do
      expect { described_class.start([ "list", "--tier", "core" ]) }.to output(/app_name/).to_stdout
      expect { described_class.start([ "list", "--tier", "core" ]) }.not_to output(/rubocop/).to_stdout
    end

    it "filters by --tier addon" do
      expect { described_class.start([ "list", "--tier", "addon" ]) }.to output(/rubocop/).to_stdout
      expect { described_class.start([ "list", "--tier", "addon" ]) }.not_to output(/app_name/).to_stdout
    end
  end

  describe "info" do
    it "shows metadata for a stubbed step without crashing" do
      expect { described_class.start([ "info", "ci" ]) }.to output(/not yet implemented/).to_stdout
      expect { described_class.start([ "info", "ci" ]) }.to output(/Configure CI/).to_stdout
    end

    it "raises a clear error for an unknown step" do
      expect { described_class.new.info("nope") }.to raise_error(
        described_class::UnknownStepError,
        /Unknown step: :nope/
      )
    end
  end

  describe "add" do
    it "has no Thor options" do
      expect(described_class.all_commands["add"].options.keys).to be_empty
    end

    it "is not yet implemented" do
      cli = described_class.new
      expect { cli.add("rubocop") }.to raise_error(NotImplementedError)
    end
  end
end
