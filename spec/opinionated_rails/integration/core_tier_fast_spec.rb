# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe "core new command (fast)" do
  let(:tmp) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(tmp)
  end

  it "generates an app with RSpec and rspec-rails in the Gemfile" do
    Dir.chdir(tmp) do
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "RSpec" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      expect(File.read(File.join(tmp, "testapp", "Gemfile"))).to include("rspec-rails")
    end
  end

  it "generates an app with Minitest and a test/ directory" do
    Dir.chdir(tmp) do
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      expect(Dir.exist?(File.join(tmp, "testapp", "test"))).to be true
      expect(File.read(File.join(tmp, "testapp", "Gemfile"))).not_to include("rspec-rails")
    end
  end
end
