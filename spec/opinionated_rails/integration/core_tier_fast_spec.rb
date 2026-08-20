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

      expect(File).to exist(File.join(app, "AGENT.md"))
      expect(File).to exist(File.join(app, "STYLE.md"))
      expect(File).to exist(File.join(app, "app/javascript/application.jsx"))
      expect(File).not_to exist(File.join(app, "app/javascript/application.js"))
      expect(File.read(File.join(app, "app/javascript/application.jsx"))).to include("react-dom/client")
      expect(File).to exist(File.join(app, "app/javascript/router.jsx"))
      expect(File).to exist(File.join(app, "app/javascript/images"))
      expect(File).to exist(File.join(app, "jsconfig.json"))
      expect(File.read(File.join(app, "package.json"))).to include("react-router-dom")
      expect(File.read(File.join(app, "package.json"))).to include("--alias:@=app/javascript")
      expect(File.read(File.join(app, "package.json"))).to include("tailwindcss")
      expect(File.read(File.join(app, "package.json"))).to include("build:css")
      expect(File.read(File.join(app, ".eslintrc.json"))).to include("plugin:react/recommended")
      expect(File).to exist(File.join(app, "app/controllers/spa_controller.rb"))
      expect(File.read(File.join(app, "app/views/spa/root.html.erb"))).to include('<div id="root">')
      expect(File.read(File.join(app, "config/routes.rb"))).to include('get "*path"')
      expect(File).to exist(File.join(app, "app/assets/stylesheets/application.tailwind.css"))
      expect(File).to exist(File.join(app, "config/tailwind.config.js"))
      expect(File.read(File.join(app, "config/tailwind.config.js"))).to include("app/javascript/**/*.{js,jsx}")
      expect(File.read(File.join(app, "Procfile.dev"))).to include("css: npx tailwindcss")
      expect(File.read(File.join(app, "app/views/layouts/application.html.erb"))).to include('stylesheet_link_tag "tailwind"')
    end
  end

  it "generates a Stimulus app with linting and no JSX files" do
    Dir.chdir(tmp) do
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest", "1", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      app = File.join(tmp, "testapp")

      expect(File).to exist(File.join(app, "AGENT.md"))
      expect(File).to exist(File.join(app, "STYLE.md"))
      expect(File).not_to exist(File.join(app, "app/javascript/application.jsx"))
      expect(File).not_to exist(File.join(app, "app/javascript/router.jsx"))
      expect(File.read(File.join(app, ".eslintrc.json"))).not_to include("react")
      expect(File.read(File.join(app, "package.json"))).to include("lint:js")
      expect(File.read(File.join(app, "Gemfile"))).to include("tailwindcss-rails")
      expect(File).to exist(File.join(app, "app/assets/stylesheets/application.tailwind.css"))
      expect(File).to exist(File.join(app, "config/tailwind.config.js"))
      expect(File).to exist(File.join(app, "app/controllers/spa_controller.rb"))
      expect(File.read(File.join(app, "app/views/spa/root.html.erb"))).to include("Not Found")
      expect(File.read(File.join(app, "config/routes.rb"))).to include('get "*path"')
      expect(File.read(File.join(app, "app/views/layouts/application.html.erb"))).to include('stylesheet_link_tag "tailwind"')
    end
  end

  it "generates an API-only app without SPA or Tailwind" do
    Dir.chdir(tmp) do
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "2", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      app = File.join(tmp, "testapp")

      expect(File).to exist(File.join(app, "AGENT.md"))
      expect(File).to exist(File.join(app, "STYLE.md"))
      expect(File).not_to exist(File.join(app, "app/controllers/spa_controller.rb"))
      expect(File).not_to exist(File.join(app, "app/assets/stylesheets/application.tailwind.css"))
      expect(File.read(File.join(app, "config/routes.rb"))).not_to include('get "*path"')
      expect(File).not_to exist(File.join(app, "package.json"))
    end
  end
end
