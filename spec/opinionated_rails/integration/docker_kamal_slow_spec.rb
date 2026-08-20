# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe "docker_kamal (slow)", integration: true do
  it "generates a real Dockerfile and .dockerignore via dockerfile-rails" do
    Dir.mktmpdir do |tmp|
      allow(Thor::Shell::Basic).to receive(:new).and_return(TestShell.new([ "testapp", "", "", "Minitest" ]))
      Dir.chdir(tmp) do
        OpinionatedRails::CLI.start([ "new" ])
      end

      app = File.join(tmp, "testapp")
      expect(File).to exist(File.join(app, "Dockerfile"))
      expect(File).to exist(File.join(app, ".dockerignore"))
      expect(File).not_to exist(File.join(app, "config/deploy.yml"))
      expect(File).not_to exist(File.join(app, ".kamal/secrets"))
    end
  end

  it "additionally scaffolds config/deploy.yml and .kamal/secrets when Kamal is enabled" do
    Dir.mktmpdir do |tmp|
      # app_name, database, app_type, testing, frontend, rubocop, vcr, js_lint, docker_kamal=yes
      allow(Thor::Shell::Basic).to receive(:new).and_return(
        TestShell.new([ "testapp", "", "", "Minitest", "", "", "", "", "yes" ])
      )
      Dir.chdir(tmp) do
        OpinionatedRails::CLI.start([ "new" ])
      end

      app = File.join(tmp, "testapp")
      expect(File).to exist(File.join(app, "Dockerfile"))
      expect(File).to exist(File.join(app, "config/deploy.yml"))
      expect(File).to exist(File.join(app, ".kamal/secrets"))
    end
  end
end
