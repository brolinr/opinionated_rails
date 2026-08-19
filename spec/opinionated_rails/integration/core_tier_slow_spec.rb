# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe "core new command (slow)", integration: true do
  it "generates an app, installs the bundle, and runs rspec:install" do
    Dir.mktmpdir do |tmp|
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "RSpec" ]))
      Dir.chdir(tmp) do
        OpinionatedRails::CLI.start([ "new" ])
      end
      expect(Dir.exist?(File.join(tmp, "testapp", "spec"))).to be true
    end
  end
end
