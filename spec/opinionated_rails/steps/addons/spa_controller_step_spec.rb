# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::SpaControllerStep do
  def build_context(frontend: :stimulus_hotwire, app_type: :full_stack, app_path: Dir.mktmpdir)
    ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new([]))
    ctx.set_output(:app_type, { app_type: app_type })
    ctx.set_output(:frontend, { frontend: frontend })
    ctx
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:spa_controller)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([ :frontend ])
    expect(described_class.prompts).to be_a(String)
  end

  it "is skipped for API-only apps" do
    ctx = build_context(app_type: :api_only, app_path: Dir.mktmpdir)
    step = described_class.new
    expect(step.if_condition(ctx)).to be false

    step.generate(ctx)

    expect(ctx.output(:spa_controller)).to be_nil
    expect(File).not_to exist(File.join(ctx.app_path, "app/controllers/spa_controller.rb"))
  end

  it "writes a React mount view and catch-all route" do
    Dir.mktmpdir do |tmp|
      routes = File.join(tmp, "config")
      FileUtils.mkdir_p(routes)
      File.write(File.join(routes, "routes.rb"), "Rails.application.routes.draw do\nend\n")

      ctx = build_context(frontend: :react, app_path: tmp)
      described_class.new.generate(ctx)

      expect(ctx.output(:spa_controller)).to eq({ spa_controller: :react_mount })
      expect(File.read(File.join(tmp, "app/views/spa/root.html.erb"))).to include('<div id="root">')
      expect(File.read(File.join(tmp, "config/routes.rb"))).to include('get "*path"')
      expect(File.read(File.join(tmp, "config/routes.rb"))).to include('root "spa#root"') # `*path` does not match "/"
    end
  end

  it "does not add routes twice" do
    Dir.mktmpdir do |tmp|
      FileUtils.mkdir_p(File.join(tmp, "config"))
      File.write(File.join(tmp, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")

      ctx = build_context(frontend: :react, app_path: tmp)
      2.times { described_class.new.generate(ctx) }

      expect(File.read(File.join(tmp, "config/routes.rb")).scan("spa#root").size).to eq(2) # root + catch-all, once each
    end
  end

  it "does not add a root route for the Stimulus 404 fallback" do
    Dir.mktmpdir do |tmp|
      FileUtils.mkdir_p(File.join(tmp, "config"))
      File.write(File.join(tmp, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")

      described_class.new.generate(build_context(frontend: :stimulus_hotwire, app_path: tmp))

      expect(File.read(File.join(tmp, "config/routes.rb"))).not_to include("root ")
    end
  end

  it "writes a fallback 404 view and catch-all route for Stimulus" do
    Dir.mktmpdir do |tmp|
      routes = File.join(tmp, "config")
      FileUtils.mkdir_p(routes)
      File.write(File.join(routes, "routes.rb"), "Rails.application.routes.draw do\nend\n")

      ctx = build_context(frontend: :stimulus_hotwire, app_path: tmp)
      described_class.new.generate(ctx)

      expect(ctx.output(:spa_controller)).to eq({ spa_controller: :fallback_404 })
      expect(File.read(File.join(tmp, "app/views/spa/root.html.erb"))).to include("Not Found")
      expect(File.read(File.join(tmp, "config/routes.rb"))).to include('get "*path"')
    end
  end
end
