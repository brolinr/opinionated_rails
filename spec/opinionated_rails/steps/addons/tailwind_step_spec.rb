# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Addons::TailwindStep do
  def build_context(frontend: :stimulus_hotwire, app_path: Dir.mktmpdir)
    ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new([]))
    ctx.set_output(:frontend, { frontend: frontend })
    ctx
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:tailwind)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([ :frontend ])
    expect(described_class.prompts).to be_a(String)
  end

  it "is skipped when there is no frontend" do
    ctx = build_context(frontend: :none)
    step = described_class.new
    expect(step.if_condition(ctx)).to be false

    step.generate(ctx)

    expect(ctx.output(:tailwind)).to be_nil
    expect(File).not_to exist(File.join(ctx.app_path, "app/assets/stylesheets/application.tailwind.css"))
  end

  it "configures tailwindcss-rails for Stimulus" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "Gemfile"), "source \"https://rubygems.org\"\n")

      layout_dir = File.join(tmp, "app/views/layouts")
      FileUtils.mkdir_p(layout_dir)
      File.write(File.join(layout_dir, "application.html.erb"), "<head>\n  <%= stylesheet_link_tag \"application\", \"data-turbo-track\": \"reload\" %>\n</head>\n")

      ctx = build_context(frontend: :stimulus_hotwire, app_path: tmp)
      described_class.new.generate(ctx)

      expect(ctx.output(:tailwind)).to eq({ tailwind: true })
      expect(File.read(File.join(tmp, "Gemfile"))).to include("tailwindcss-rails")
      expect(File.read(File.join(tmp, "app/assets/stylesheets/application.tailwind.css"))).to include("@tailwind base")
      expect(File.read(File.join(tmp, "config/tailwind.config.js"))).to include("app/views/**/*.html.erb")
      expect(File.read(File.join(tmp, "app/views/layouts/application.html.erb"))).to include('stylesheet_link_tag "tailwind"')
    end
  end

  it "adds a pinned Tailwind npm package for React" do
    Dir.mktmpdir do |tmp|
      File.write(File.join(tmp, "package.json"), JSON.pretty_generate({ "scripts" => {}, "dependencies" => { "react" => "18.2.0" } }))

      layout_dir = File.join(tmp, "app/views/layouts")
      FileUtils.mkdir_p(layout_dir)
      File.write(File.join(layout_dir, "application.html.erb"), "<head>\n  <%= stylesheet_link_tag \"application\", \"data-turbo-track\": \"reload\" %>\n</head>\n")

      File.write(File.join(tmp, "Procfile.dev"), "web: bin/rails server\njs: yarn build --watch\n")

      ctx = build_context(frontend: :react, app_path: tmp)
      described_class.new.generate(ctx)

      package = JSON.parse(File.read(File.join(tmp, "package.json")))
      expect(package["devDependencies"]["tailwindcss"]).to eq(described_class::TAILWIND_VERSION)
      expect(package["scripts"]["build:css"]).to include("npx tailwindcss")

      config = File.read(File.join(tmp, "config/tailwind.config.js"))
      expect(config).to include("app/javascript/**/*.{js,jsx}")
      expect(File.read(File.join(tmp, "app/assets/stylesheets/application.tailwind.css"))).to include("@tailwind utilities")
      expect(File.read(File.join(tmp, "Procfile.dev"))).to include("css: npx tailwindcss")
      expect(File.read(File.join(tmp, "app/views/layouts/application.html.erb"))).to include('stylesheet_link_tag "tailwind"')
    end
  end
end
