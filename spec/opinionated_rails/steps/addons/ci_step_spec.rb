# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe OpinionatedRails::Steps::Addons::CiStep do
  def build_context(answers, app_path: Dir.mktmpdir, test_framework: :minitest, js_lint: false)
    ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new(answers))
    ctx.set_output(:testing, { test_framework: test_framework })
    ctx.set_output(:js_lint, { js_lint: js_lint }) unless js_lint.nil?
    ctx
  end

  it "has the expected id, tier, needs, and prompts" do
    expect(described_class.id).to eq(:ci)
    expect(described_class.tier).to eq(:addon)
    expect(described_class.needs).to eq([ :rubocop, :testing ])
    expect(described_class.prompts).to be_a(String)
  end

  it "is on by default and writes a valid workflow file" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:ci)).to eq({ ci: true })

      path = File.join(tmp, ".github/workflows/ci.yml")
      expect(File).to exist(path)
      parsed = YAML.safe_load_file(path, permitted_classes: [ Symbol ], aliases: true)
      expect(parsed["jobs"]).to have_key("test")
      expect(parsed["jobs"]).to have_key("rubocop")
    end
  end

  it "uses bundle exec rspec for the RSpec test job" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp, test_framework: :rspec)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      content = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(content).to include("bundle exec rspec")
    end
  end

  it "uses bin/rails test for the Minitest test job" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp, test_framework: :minitest)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      content = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(content).to include("bin/rails test")
    end
  end

  it "includes a js_lint job only when js_lint output is true" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp, js_lint: true)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      content = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(content).to include("js_lint:")
      expect(content).to include("yarn run lint:js") # the app is installed with yarn, so CI must not use npm
    end
  end

  it "omits the js_lint job when js_lint output is absent" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "" ], app_path: tmp, js_lint: nil)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      content = File.read(File.join(tmp, ".github/workflows/ci.yml"))
      expect(content).not_to include("js_lint:")
    end
  end

  it "writes no workflow file when disabled" do
    Dir.mktmpdir do |tmp|
      ctx = build_context([ "no" ], app_path: tmp)
      step = described_class.new
      step.prompt(ctx)
      step.generate(ctx)

      expect(ctx.output(:ci)).to eq({ ci: false })
      expect(File).not_to exist(File.join(tmp, ".github/workflows/ci.yml"))
    end
  end
  describe "workflow content" do
    def render(database: :sqlite3, stack: :solid, frontend: :none, bundler: nil, test_framework: :minitest, js_lint: false)
      Dir.mktmpdir do |tmp|
        FileUtils.mkdir_p(File.join(tmp, "bin"))
        FileUtils.touch([ File.join(tmp, "bin/brakeman"), File.join(tmp, "bin/bundler-audit") ])
        ctx = build_context([ "" ], app_path: tmp, test_framework: test_framework, js_lint: js_lint)
        ctx.set_output(:database, { database: database })
        ctx.set_output(:solid_stack, { solid_stack: stack })
        ctx.set_output(:frontend, { frontend: frontend })
        ctx.answer(:bundler, bundler) if bundler
        step = described_class.new
        step.prompt(ctx)
        step.generate(ctx)
        YAML.safe_load_file(File.join(tmp, ".github/workflows/ci.yml"))
      end
    end

    it "uses least-privilege permissions, concurrency and job timeouts" do
      workflow = render

      expect(workflow["permissions"]).to eq({ "contents" => "read" })
      expect(workflow["concurrency"]["cancel-in-progress"]).to be true
      expect(workflow["jobs"].values).to all(include("timeout-minutes" => 15))
    end

    it "keeps the Brakeman and bundler-audit scans that --skip-ci removes" do
      steps = render.dig("jobs", "security", "steps").map { |step| step["run"] }.compact

      expect(steps).to include("bin/brakeman --no-pager", "bin/bundler-audit")
    end

    it "starts no services for SQLite on the Solid stack" do
      test_job = render.dig("jobs", "test")

      expect(test_job).not_to have_key("services")
      expect(test_job["env"]).to eq({ "RAILS_ENV" => "test" })
    end

    it "provisions PostgreSQL and Redis when chosen" do
      test_job = render(database: :postgresql, stack: :redis).dig("jobs", "test")

      expect(test_job["services"].keys).to contain_exactly("postgres", "redis")
      expect(test_job["env"]).to include("DATABASE_URL" => "postgres://postgres:postgres@localhost:5432/ci_test", "REDIS_URL" => "redis://localhost:6379/1")
    end

    it "provisions MySQL and installs its client library" do
      test_job = render(database: :mysql2).dig("jobs", "test")

      expect(test_job["services"].keys).to eq([ "mysql" ])
      expect(test_job["env"]["DATABASE_URL"]).to eq("mysql2://root@127.0.0.1:3306/ci_test")
      expect(test_job["steps"].map { |step| step["run"] }.compact.join).to include("libmysqlclient-dev")
    end

    it "sets up Node and builds the JavaScript and CSS for React apps" do
      steps = render(frontend: :react).dig("jobs", "test", "steps")

      expect(steps.map { |step| step["uses"] }).to include("actions/setup-node@v4")
      expect(steps.map { |step| step["run"] }.compact).to include("yarn install", "yarn run build && yarn run build:css")
    end

    it "uses bun for a bun bundler, including setup and the lint job" do
      workflow = render(frontend: :react, bundler: :bun, js_lint: true)

      expect(workflow.dig("jobs", "test", "steps").map { |step| step["uses"] }).to include("oven-sh/setup-bun@v2")
      expect(workflow.dig("jobs", "test", "steps").map { |step| step["run"] }.compact).to include("bun install")
      expect(workflow.dig("jobs", "js_lint", "steps").map { |step| step["run"] }.compact).to eq([ "bun install", "bun run lint:js" ])
    end

    it "creates and migrates the database before running the tests (a fresh app has no schema.rb)" do
      runs = render(test_framework: :rspec).dig("jobs", "test", "steps").map { |step| step["run"] }.compact

      expect(runs).to eq([ "bin/rails db:create db:migrate db:test:prepare", "bundle exec rspec" ])
    end
  end
end
