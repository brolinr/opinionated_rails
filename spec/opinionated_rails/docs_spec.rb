# frozen_string_literal: true

require "spec_helper"
require "rake"

# The docs are only useful while they match the code. These specs fail when an option, step, flag,
# message, example or link changes without the documentation changing with it.
RSpec.describe "documentation" do
  ROOT = File.expand_path("../..", __dir__)
  DOCS = File.join(ROOT, "docs")

  def read(path) = File.read(path, encoding: "UTF-8")

  def page(name) = read(File.join(DOCS, name))

  # Our pages only: not the gems Jekyll installs under docs/vendor, or its build output.
  def pages
    Dir.glob(File.join(DOCS, "**/*.md")).reject { |file| file.match?(%r{/docs/(vendor|_site|\.bundle|\.jekyll-cache)/}) } +
      [ File.join(ROOT, "README.md") ]
  end

  def lib_source = Dir.glob(File.join(ROOT, "lib/**/*.rb")).map { |file| read(file) }.join("\n")

  describe "config file reference" do
    # spellings accepted for compatibility but not documented as the canonical value
    ALIASES = [ "rails credentials", "factory_bot", "stimulus+hotwire", "y", "n" ].freeze

    it "lists every config key" do
      OpinionatedRails::AnswerShell::LABELS.each_key do |key|
        expect(page("config-file.md")).to include("`#{key}`"), "config key `#{key}` is not documented in docs/config-file.md"
      end
    end

    it "lists every accepted value for every key" do
      OpinionatedRails::AnswerShell::CHOICES.each do |key, values|
        (values - ALIASES - %w[ yes no ]).each do |value|
          expect(page("config-file.md")).to include("`#{value}`"), "value `#{value}` of `#{key}` is not documented in docs/config-file.md"
        end
      end
    end

    it "documents each yes/no key as a yes/no switch" do
      yes_no = OpinionatedRails::AnswerShell::CHOICES.select { |_, values| values == OpinionatedRails::AnswerShell::YES_NO }.keys

      yes_no.each { |key| expect(page("config-file.md")).to match(/`#{key}` \| yes\/no/) }
    end

    it "shows example files that are exactly the fixtures the test matrix uses" do
      %w[ api_pg react_webpack custom_everything_off ].each do |combo|
        body = read(File.join(ROOT, "spec/fixtures/combos/#{combo}.yml")).lines.reject { |line| line.start_with?("#") }.join.strip

        expect(page("config-file.md")).to include(body), "docs/config-file.md example for #{combo} no longer matches its fixture"
      end
      expect(page("config-file.md")).to include("{}") # default.yml
    end
  end

  describe "command line reference" do
    it "documents every flag of `new` and both other commands" do
      OpinionatedRails::CLI.commands["new"].options.each do |name, option|
        flag = "--#{name.to_s.tr('_', '-')}"
        expect(page("command-line.md")).to include(flag), "#{flag} is not documented in docs/command-line.md"
        Array(option.aliases).each { |short| expect(page("command-line.md")).to include(short) }
      end
      %w[ list info ].each { |command| expect(page("command-line.md")).to include("opinionated_rails #{command}") }
    end
  end

  describe "step reference" do
    before(:all) do
      Rake.application = Rake::Application.new
      Rake.application.rake_require("docs", [ File.join(ROOT, "rakelib") ])
    end

    it "is exactly what `rake docs:steps` generates (run it, then commit the result)" do
      expect(page("steps.md")).to eq(DocsSteps.render)
    end

    it "covers every step" do
      OpinionatedRails.step_classes.each do |step|
        expect(page("steps.md")).to include("## `#{step.id}`")
      end
    end
  end

  describe "troubleshooting" do
    # [fragment of a message the tool prints, in lib/ and docs/troubleshooting.md]
    FRAGMENTS = [
      "Rails is not installed", "needs Rails", "already exists", "Unknown option(s):", "Invalid value", "Choose one of:",
      "Config file not found", "must be a YAML mapping", "is not valid YAML", "No app name given (input ended)",
      "Invalid app name", "needs tools that are not on your PATH", "Ignored options (their prompt did not apply)",
      "Authentication is skipped for API-only apps", "not found; run", "still reports offenses",
      "could not switch", "has no Solid Cable or Redis production block", "add these lines yourself",
      "mailer settings were not added", "Rails credentials may not work as expected", "editor/TypeScript tooling only",
      "The partially generated app is in", "failed:", "REDIS_URL is not set"
    ].freeze

    it "documents every user-facing message by a fragment that is still in the code" do
      FRAGMENTS.each do |fragment|
        expect(lib_source).to include(fragment), "`#{fragment}` is no longer in lib/: update docs/troubleshooting.md and this list"
        expect(page("troubleshooting.md")).to include(fragment), "`#{fragment}` is not in docs/troubleshooting.md"
      end
    end

    # A new warning or user-input error has to be added to docs/troubleshooting.md and to FRAGMENTS above;
    # this count makes forgetting that a failing test.
    it "notices a new warning or error message that nobody documented" do
      warnings = lib_source.scan("Warning:").size
      raises = %w[ cli.rb answer_shell.rb prerequisites.rb rails_version_guard.rb steps/core/app_name_step.rb ].sum do |file|
        read(File.join(ROOT, "lib/opinionated_rails", file)).scan(/\braise\s*\(?\s*(?:OpinionatedRails::|UnsupportedError|Error)/).size
      end

      expect([ warnings, raises ]).to eq([ 8, 18 ]),
                                      "a Warning:/raise was added or removed (now #{warnings}/#{raises}): document it in docs/troubleshooting.md, " \
                                      "add a fragment to FRAGMENTS, then update these counts"
    end
  end

  describe "links" do
    def slug(heading)
      heading.downcase.gsub(/`/, "").gsub(/[^\w\s-]/, "").strip.tr(" ", "-")
    end

    def headings(file) = read(file).lines.grep(/^\#{1,6} /).map { |line| slug(line.sub(/^#+ /, "").sub(/\{:.*\}/, "")) }

    def target_for(from, href)
      path, fragment = href.split("#", 2)
      base = File.dirname(from)
      path = "index" if path.to_s.empty? && false
      resolved = File.expand_path(path.to_s, base)
      resolved = resolved.sub(/\.html\z/, ".md")
      resolved = File.join(resolved, "index.md") if File.directory?(resolved)
      [ resolved, fragment ]
    end

    it "resolves every relative link and anchor in the docs and README" do
      broken = []

      pages.each do |file|
        read(file).scan(/\]\(([^)\s]+)\)/).flatten.each do |href|
          next if href.start_with?("http", "mailto:", "#")

          resolved, fragment = target_for(file, href)
          if !File.exist?(resolved)
            broken << "#{file.delete_prefix("#{ROOT}/")}: #{href} (no such file)"
          elsif fragment && resolved.end_with?(".md") && !headings(resolved).include?(fragment)
            broken << "#{file.delete_prefix("#{ROOT}/")}: #{href} (no such heading)"
          end
        end
      end

      expect(broken).to eq([])
    end
  end
end
