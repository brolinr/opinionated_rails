# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe "auth_step (slow)", integration: true do
  it "runs the real Rails 8 authentication generator" do
    Dir.mktmpdir do |tmp|
      # app_name, database, app_type, testing=Minitest, frontend, rubocop, services, auth_model,
      # auth_strategy=Rails8, mailer, vcr, js_lint, docker_kamal
      allow(Thor::Shell::Basic).to receive(:new).and_return(
        TestShell.new([ "testapp", "", "", "Minitest", "", "", "", "", "2", "", "", "", "" ])
      )
      Dir.chdir(tmp) do
        OpinionatedRails::CLI.start([ "new" ])
      end

      app = File.join(tmp, "testapp")
      expect(File).to exist(File.join(app, "app/models/user.rb"))
      expect(File).to exist(File.join(app, "app/models/session.rb"))
      expect(File.read(File.join(app, "Gemfile"))).to include("bcrypt")
    end
  end

  it "runs the real Devise generators with a custom model name and views for full-stack apps" do
    Dir.mktmpdir do |tmp|
      # app_name, database, app_type, testing=Minitest, frontend, rubocop, services, auth_model=Account,
      # auth_strategy=Devise, mailer, vcr, js_lint, docker_kamal
      allow(Thor::Shell::Basic).to receive(:new).and_return(
        TestShell.new([ "testapp", "", "", "Minitest", "", "", "", "Account", "devise", "", "", "", "" ])
      )
      Dir.chdir(tmp) do
        OpinionatedRails::CLI.start([ "new" ])
      end

      app = File.join(tmp, "testapp")
      expect(File).to exist(File.join(app, "app/models/account.rb"))
      expect(Dir.exist?(File.join(app, "app/views/devise"))).to be true
    end
  end
end
