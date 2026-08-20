# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::PaginationStep do
  def build_context(answers, app_path: Dir.mktmpdir)
    OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
  end

  def write_app_files(tmp)
    FileUtils.mkdir_p(File.join(tmp, "app/controllers"))
    FileUtils.mkdir_p(File.join(tmp, "app/helpers"))
    File.write(File.join(tmp, "app/controllers/application_controller.rb"), "class ApplicationController < ActionController::Base\nend\n")
    File.write(File.join(tmp, "app/helpers/application_helper.rb"), "module ApplicationHelper\nend\n")
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:pagination)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([])
    expect(described_class.prompts).to be_a(String)
  end

  it "defaults to pagy" do
    Dir.mktmpdir do |tmp|
      write_app_files(tmp)
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:pagination)).to eq({ pagination: :pagy })
      expect(File.read(File.join(tmp, "Gemfile"))).to include('gem "pagy", "43.6.1"')
      expect(File).to exist(File.join(tmp, "config/initializers/pagy.rb"))
      expect(File.read(File.join(tmp, "app/controllers/application_controller.rb"))).to include("include Pagy::Backend")
      expect(File.read(File.join(tmp, "app/helpers/application_helper.rb"))).to include("include Pagy::Frontend")
    end
  end

  it "adds only the gem for geared_pagination, no initializer or includes" do
    Dir.mktmpdir do |tmp|
      write_app_files(tmp)
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "1" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:pagination)).to eq({ pagination: :geared_pagination })
      expect(File.read(File.join(tmp, "Gemfile"))).to include('gem "geared_pagination", "1.2.0"')
      expect(File).not_to exist(File.join(tmp, "config/initializers/pagy.rb"))
      expect(File.read(File.join(tmp, "app/controllers/application_controller.rb"))).not_to include("Pagy")
      expect(File.read(File.join(tmp, "app/helpers/application_helper.rb"))).not_to include("Pagy")
    end
  end

  it "does not duplicate includes or gems on repeated generate calls" do
    Dir.mktmpdir do |tmp|
      write_app_files(tmp)
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      ctx = build_context([ "pagy" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)
      step.generate(ctx)

      expect(File.read(File.join(tmp, "Gemfile")).scan('gem "pagy"').size).to eq(1)
      expect(File.read(File.join(tmp, "app/controllers/application_controller.rb")).scan("Pagy::Backend").size).to eq(1)
    end
  end
end
