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
      # app_name, database, app_type, testing=RSpec, frontend, factory_or_fixtures, vcr, js_lint
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "RSpec", "", "", "", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      app = File.join(tmp, "testapp")

      expect(File.read(File.join(app, "Gemfile"))).to include("rspec-rails")
      expect(File.read(File.join(app, "Gemfile"))).to include("factory_bot_rails")
      expect(Dir.exist?(File.join(app, "spec/factories"))).to be true
    end
  end

  it "generates an app with Minitest and a test/ directory" do
    Dir.chdir(tmp) do
      # app_name, database, app_type, testing=Minitest, frontend, vcr, js_lint (no factory prompt)
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest", "", "", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      app = File.join(tmp, "testapp")

      expect(Dir.exist?(File.join(app, "test"))).to be true
      expect(File.read(File.join(app, "Gemfile"))).not_to include("rspec-rails")
      expect(File.read(File.join(app, "Gemfile"))).not_to include("factory_bot_rails")
      expect(File).not_to exist(File.join(app, "spec/factories"))
    end
  end

  it "generates a React app with JSX and the esbuild alias" do
    Dir.chdir(tmp) do
      # app_name, database, app_type, testing=Minitest, frontend=React, bundler, vcr, js_lint
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest", "2", "", "", "" ]))
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
      # app_name, database, app_type, testing=Minitest, frontend=Stimulus, vcr, js_lint
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest", "1", "", "" ]))
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
      # app_name, database, app_type=API-only, testing=Minitest (default), vcr
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "2", "", "" ]))
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

  it "generates RSpec + Fixtures when explicitly chosen" do
    Dir.chdir(tmp) do
      # app_name, database, app_type, testing=RSpec, frontend, factory_or_fixtures=Fixtures, vcr, js_lint
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "RSpec", "", "2", "", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      app = File.join(tmp, "testapp")

      expect(File.read(File.join(app, "Gemfile"))).to include("rspec-rails")
      expect(File.read(File.join(app, "Gemfile"))).not_to include("factory_bot_rails")
      expect(File).not_to exist(File.join(app, "spec/factories"))
    end
  end

  it "enables VCR for RSpec with Gemfile gems and support config" do
    Dir.chdir(tmp) do
      # app_name, database, app_type, testing=RSpec, frontend, factory_or_fixtures, vcr=yes, js_lint
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "RSpec", "", "", "yes", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      app = File.join(tmp, "testapp")

      gemfile = File.read(File.join(app, "Gemfile"))
      expect(gemfile).to include("gem \"vcr\"")
      expect(gemfile).to include("gem \"webmock\"")
      expect(File.read(File.join(app, "spec/support/vcr.rb"))).to include("filter_sensitive_data")
      expect(File.read(File.join(app, "spec/rails_helper.rb"))).to include('require "support/vcr"')

      gitignore_path = File.join(app, ".gitignore")
      expect(File.read(gitignore_path)).not_to include("cassette") if File.exist?(gitignore_path)
    end
  end

  it "enables VCR for Minitest with test_helper.rb wiring" do
    Dir.chdir(tmp) do
      # app_name, database, app_type, testing=Minitest, frontend, vcr=yes, js_lint
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest", "", "yes", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      app = File.join(tmp, "testapp")

      gemfile = File.read(File.join(app, "Gemfile"))
      expect(gemfile).to include("gem \"vcr\"")
      expect(gemfile).to include("gem \"webmock\"")
      expect(File.read(File.join(app, "test/support/vcr.rb"))).to include("filter_sensitive_data")
      expect(File.read(File.join(app, "test/test_helper.rb"))).to include('require_relative "support/vcr"')
    end
  end

  it "leaves VCR disabled by default" do
    Dir.chdir(tmp) do
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest", "", "", "" ]))
      OpinionatedRails::CLI.start([ "new", "--skip-bundle-install" ])
      app = File.join(tmp, "testapp")

      expect(File.read(File.join(app, "Gemfile"))).not_to include("gem \"vcr\"")
      expect(File).not_to exist(File.join(app, "test/support/vcr.rb"))
    end
  end
end
