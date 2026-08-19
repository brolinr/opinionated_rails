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
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "RSpec", "", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      expect(File.read(File.join(tmp, "testapp", "Gemfile"))).to include("rspec-rails")
    end
  end

  it "generates an app with Minitest and a test/ directory" do
    Dir.chdir(tmp) do
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest", "", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      expect(Dir.exist?(File.join(tmp, "testapp", "test"))).to be true
      expect(File.read(File.join(tmp, "testapp", "Gemfile"))).not_to include("rspec-rails")
    end
  end

  it "generates a React app with JSX and the esbuild alias" do
    Dir.chdir(tmp) do
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest", "2", "", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      app = File.join(tmp, "testapp")

      expect(File).to exist(File.join(app, "app/javascript/application.jsx"))
      expect(File).not_to exist(File.join(app, "app/javascript/application.js"))
      expect(File.read(File.join(app, "app/javascript/application.jsx"))).to include("react-dom/client")
      expect(File).to exist(File.join(app, "app/javascript/router.jsx"))
      expect(File).to exist(File.join(app, "app/javascript/images"))
      expect(File).to exist(File.join(app, "jsconfig.json"))
      expect(File.read(File.join(app, "package.json"))).to include("react-router-dom")
      expect(File.read(File.join(app, "package.json"))).to include("--alias:@=app/javascript")
      expect(File.read(File.join(app, ".eslintrc.json"))).to include("plugin:react/recommended")
    end
  end

  it "generates a Stimulus app with linting and no JSX files" do
    Dir.chdir(tmp) do
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest", "1", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      app = File.join(tmp, "testapp")

      expect(File).not_to exist(File.join(app, "app/javascript/application.jsx"))
      expect(File).not_to exist(File.join(app, "app/javascript/router.jsx"))
      expect(File.read(File.join(app, ".eslintrc.json"))).not_to include("react")
      expect(File.read(File.join(app, "package.json"))).to include("lint:js")
    end
  end
end
