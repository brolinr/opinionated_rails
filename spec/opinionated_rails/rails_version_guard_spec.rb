# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::RailsVersionGuard do
  %w[ 8.1.0 8.1.4 8.2.0 8.9.1 ].each do |version|
    it "accepts Rails #{version}" do
      expect(described_class.from_string(version).assert!).to be true
    end
  end

  %w[ 6.1.0 7.1.0 8.0.1 9.0.0 9.0.0.beta ].each do |version|
    it "rejects Rails #{version}" do
      expect { described_class.from_string(version).assert! }.to raise_error(
        described_class::UnsupportedError,
        /Rails #{Regexp.escape(version)} is not supported.*8\.1/
      )
    end
  end

  it "rejects a version it cannot parse" do
    expect { described_class.from_string("not-a-version").assert! }
      .to raise_error(described_class::UnsupportedError, /not supported/)
  end

  describe ".installed" do
    it "reads the version of the installed rails executable" do
      allow(Open3).to receive(:capture2e).and_return([ "Rails 8.1.4\n", instance_double(Process::Status, success?: true) ])

      expect(described_class.installed).to eq("8.1.4")
    end

    it "explains how to install Rails when the executable is missing" do
      allow(Open3).to receive(:capture2e).and_raise(Errno::ENOENT)

      expect { described_class.installed }.to raise_error(described_class::UnsupportedError, /gem install rails/)
    end

    it "fails when the command itself fails" do
      allow(Open3).to receive(:capture2e).and_return([ "boom", instance_double(Process::Status, success?: false) ])

      expect { described_class.installed }.to raise_error(described_class::UnsupportedError, /rails --version/)
    end
  end

  it "checks the installed version in one call" do
    allow(described_class).to receive(:installed).and_return("7.2.0")

    expect { described_class.check_installed! }.to raise_error(described_class::UnsupportedError, /7\.2\.0/)
  end
end
