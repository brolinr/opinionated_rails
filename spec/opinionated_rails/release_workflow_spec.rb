# frozen_string_literal: true

require "spec_helper"
require "yaml"

# The release workflow publishes to RubyGems, so its safety properties are pinned here:
# it must not be triggerable by anything but a version tag, must not need a stored API key,
# and must not publish before the tests have passed.
RSpec.describe "release workflow" do
  let(:path) { File.expand_path("../../.github/workflows/release.yml", __dir__) }
  let(:text) { File.read(path, encoding: "UTF-8") }
  let(:workflow) { YAML.safe_load(text) }
  let(:jobs) { workflow.fetch("jobs") }

  # YAML 1.1 reads the key `on` as true
  def triggers = workflow["on"] || workflow[true]

  it "runs only when a version tag is pushed" do
    expect(triggers.keys).to eq([ "push" ])
    expect(triggers.dig("push", "tags")).to eq([ "v*" ])
    expect(triggers["push"]).not_to have_key("branches")
  end

  it "uses trusted publishing, with no stored RubyGems credentials" do
    expect(text).not_to match(/secrets\./)
    expect(text).not_to match(/RUBYGEMS_API_KEY|GEM_HOST_API_KEY/)
    expect(jobs.dig("publish", "permissions", "id-token")).to eq("write")
    expect(jobs.dig("publish", "steps").map { |step| step["uses"] }).to include("rubygems/release-gem@v1")
  end

  it "installs Ruby and the bundle before release-gem, which needs `bundle` on the PATH" do
    uses = jobs.dig("publish", "steps").filter_map { |step| step["uses"] }

    expect(uses.index("ruby/setup-ruby@v1")).to be < uses.index("rubygems/release-gem@v1")
    setup = jobs.dig("publish", "steps").find { |step| step["uses"] == "ruby/setup-ruby@v1" }
    expect(setup.dig("with", "bundler-cache")).to be(true)
  end

  it "is read-only by default and grants write access only to the publish job" do
    expect(workflow["permissions"]).to eq({ "contents" => "read" })
    expect(jobs["verify"]).not_to have_key("permissions")
    expect(jobs.dig("publish", "permissions", "contents")).to eq("write")
  end

  it "cannot publish before the verify job has passed" do
    expect(jobs.dig("publish", "needs")).to eq("verify")
  end

  it "verifies the version, changelog, specs, lint, pins and docs before publishing" do
    runs = jobs.dig("verify", "steps").filter_map { |step| step["run"] }.join("\n")

    expect(runs).to include("OpinionatedRails::VERSION", "CHANGELOG.md", "unreleased")
    expect(runs).to include("bundle exec rspec", "bundle exec rubocop", "rake pins:check", "rake docs:check")
  end

  it "publishes from a protected environment, so approval can be required" do
    expect(jobs.dig("publish", "environment")).to eq("rubygems")
  end

  it "does not let two releases run at once" do
    expect(workflow.dig("concurrency", "cancel-in-progress")).to be(false)
  end
end
