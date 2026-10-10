# frozen_string_literal: true

require "spec_helper"
require "open3"
require "rbconfig"

# Builds the real .gem and runs the installed executable, so a file missing from `spec.files`
# (the templates, for example) fails here instead of after publishing.
RSpec.describe "packaged gem" do
  ROOT = File.expand_path("../..", __dir__)

  before(:all) do
    @dir = Dir.mktmpdir
    @home = File.join(@dir, "gems")
    out, status = Bundler.with_unbundled_env { Open3.capture2e("gem", "build", "opinionated_rails.gemspec", "--output", File.join(@dir, "pkg.gem"), chdir: ROOT) }
    raise "gem build failed:\n#{out}" unless status.success?

    out, status = Bundler.with_unbundled_env do
      Open3.capture2e("gem", "install", File.join(@dir, "pkg.gem"), "--install-dir", @home, "--local", "--ignore-dependencies", "--no-document")
    end
    raise "gem install failed:\n#{out}" unless status.success?
  end

  after(:all) { FileUtils.rm_rf(@dir) }

  let(:exe) { File.join(@home, "bin", "opinionated_rails") }
  let(:env) { { "GEM_HOME" => @home, "GEM_PATH" => [ @home, Gem.default_dir ].join(File::PATH_SEPARATOR) } }

  def run(*args, chdir: @dir)
    Bundler.with_unbundled_env { Open3.capture2e(env, RbConfig.ruby, exe, *args, chdir: chdir) }
  end

  it "ships the metadata RubyGems needs" do
    spec = Gem::Specification.load(File.join(ROOT, "opinionated_rails.gemspec"))

    expect(spec.license).to eq("MIT")
    expect(spec.metadata["rubygems_mfa_required"]).to eq("true")
    expect(spec.metadata["changelog_uri"]).to end_with("CHANGELOG.md")
    expect(File).to exist(File.join(ROOT, "LICENSE.txt"))
  end

  it "includes every template file" do
    spec = Gem::Specification.load(File.join(ROOT, "opinionated_rails.gemspec"))
    templates = Dir.glob(File.join(ROOT, "lib/opinionated_rails/templates/**/*"), File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
    packaged = spec.files.map { |f| File.expand_path(f, ROOT) }

    expect(templates).not_to be_empty
    expect(templates - packaged).to eq([])
  end

  it "runs the installed executable" do
    out, status = run("list", "--tier", "core")

    expect(status).to be_success, out
    expect(out).to include("database (core)")
  end

  it "generates an app from the installed gem, using its packaged templates" do
    out, status = run("new", "smoke", "--yes", "--skip-bundle-install", "--database", "sqlite3")

    expect(status).to be_success, out
    app = File.join(@dir, "smoke")
    expect(File.read(File.join(app, "STYLE.md"))).to include("Project Style Guide")
    expect(File).to exist(File.join(app, ".github/PULL_REQUEST_TEMPLATE.md"))
  end

  it "exits non-zero with a message, not a backtrace, for bad input" do
    out, status = run("new", "bad", "--yes", "--skip-bundle-install", "--database", "oracle")

    expect(status).not_to be_success
    expect(out).to include('Invalid value "oracle"')
    expect(out).not_to include("lib/opinionated_rails")
  end
end
