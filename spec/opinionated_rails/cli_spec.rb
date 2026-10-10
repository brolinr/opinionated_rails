# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::CLI do
  describe "list" do
    it "lists all registered steps" do
      expect { described_class.start([ "list" ]) }.to output(/app_name/).to_stdout
      expect { described_class.start([ "list" ]) }.to output(/rubocop/).to_stdout
    end

    it "filters by --tier core" do
      expect { described_class.start([ "list", "--tier", "core" ]) }.to output(/app_name/).to_stdout
      expect { described_class.start([ "list", "--tier", "core" ]) }.not_to output(/rubocop/).to_stdout
    end

    it "filters by --tier addon" do
      expect { described_class.start([ "list", "--tier", "addon" ]) }.to output(/rubocop/).to_stdout
      expect { described_class.start([ "list", "--tier", "addon" ]) }.not_to output(/app_name/).to_stdout
    end
  end

  describe "info" do
    it "shows metadata for a step without crashing" do
      expect { described_class.start([ "info", "docker_kamal" ]) }.to output(/Configure Docker and Kamal/).to_stdout
      expect { described_class.start([ "info", "docker_kamal" ]) }.to output(/needs:\s+database, frontend/).to_stdout
    end

    it "raises a clear error for an unknown step" do
      expect { described_class.new.info("nope") }.to raise_error(
        described_class::UnknownStepError,
        /Unknown step: :nope/
      )
    end
  end

  describe "add" do
    it "has no Thor options" do
      expect(described_class.all_commands["add"].options.keys).to be_empty
    end

    it "is not yet implemented" do
      cli = described_class.new
      expect { cli.add("rubocop") }.to raise_error(NotImplementedError)
    end
  end
  describe "post-generation installs" do
    def build_context(app_path, bundler: :esbuild, skip_bundle_install: false)
      ctx = OpinionatedRails::Context.new(app_path: app_path, shell: TestShell.new([]), skip_bundle_install: skip_bundle_install)
      ctx.answer(:bundler, bundler)
      ctx
    end

    let(:cli) { described_class.new }

    before { allow(OpinionatedRails::Prerequisites).to receive(:available?).and_return(true) }

    it "installs JavaScript packages with yarn when a package.json exists" do
      Dir.mktmpdir do |tmp|
        File.write(File.join(tmp, "package.json"), "{}")
        expect(cli).to receive(:system).with("yarn", "install").and_return(true)

        cli.send(:install_javascript_packages, build_context(tmp))
      end
    end

    it "uses bun when the bundler is bun" do
      Dir.mktmpdir do |tmp|
        File.write(File.join(tmp, "package.json"), "{}")
        expect(cli).to receive(:system).with("bun", "install").and_return(true)

        cli.send(:install_javascript_packages, build_context(tmp, bundler: :bun))
      end
    end

    it "does nothing without a package.json (importmap apps)" do
      Dir.mktmpdir do |tmp|
        expect(cli).not_to receive(:system)

        cli.send(:install_javascript_packages, build_context(tmp))
      end
    end

    it "does nothing when bundle install is skipped" do
      Dir.mktmpdir do |tmp|
        File.write(File.join(tmp, "package.json"), "{}")
        expect(cli).not_to receive(:system)

        cli.send(:install_javascript_packages, build_context(tmp, skip_bundle_install: true))
      end
    end

    it "raises when the install fails" do
      Dir.mktmpdir do |tmp|
        File.write(File.join(tmp, "package.json"), "{}")
        allow(cli).to receive(:system).and_return(false)

        expect { cli.send(:install_javascript_packages, build_context(tmp)) }
          .to raise_error(OpinionatedRails::Error, /yarn install failed/)
      end
    end

    it "raises when the final bundle install fails" do
      Dir.mktmpdir do |tmp|
        allow(cli).to receive(:system).and_return(false)

        expect { cli.send(:install_bundle, build_context(tmp)) }
          .to raise_error(OpinionatedRails::Error, /final bundle install failed/)
      end
    end
  end
end
