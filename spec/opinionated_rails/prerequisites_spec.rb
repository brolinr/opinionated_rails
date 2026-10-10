# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Prerequisites do
  def build_context(frontend:, bundler: nil, skip_bundle_install: false)
    ctx = OpinionatedRails::Context.new(app_path: Dir.pwd, shell: TestShell.new([]), skip_bundle_install: skip_bundle_install)
    ctx.answer(:frontend, frontend)
    ctx.answer(:bundler, bundler) if bundler
    ctx
  end

  def path_with(*tools)
    dir = Dir.mktmpdir
    tools.each do |tool|
      File.write(File.join(dir, tool), "#!/bin/sh\n")
      File.chmod(0o755, File.join(dir, tool))
    end
    dir
  end

  it "requires nothing for a Stimulus app" do
    expect(described_class.required_tools(build_context(frontend: :stimulus_hotwire))).to eq([])
  end

  it "requires node and yarn for React with a node bundler" do
    expect(described_class.required_tools(build_context(frontend: :react, bundler: :esbuild))).to eq(%w[ node yarn ])
  end

  it "requires bun for React with bun" do
    expect(described_class.required_tools(build_context(frontend: :react, bundler: :bun))).to eq(%w[ bun ])
  end

  it "fails fast naming the missing tool and how to get it" do
    ctx = build_context(frontend: :react, bundler: :esbuild)

    expect { described_class.check!(ctx, path: path_with("node")) }
      .to raise_error(OpinionatedRails::Error, /yarn: enable it with `corepack enable`/)
  end

  it "passes when every tool is present" do
    ctx = build_context(frontend: :react, bundler: :esbuild)

    expect { described_class.check!(ctx, path: path_with("node", "yarn")) }.not_to raise_error
  end

  it "does not check anything when bundle install is skipped" do
    ctx = build_context(frontend: :react, bundler: :esbuild, skip_bundle_install: true)

    expect { described_class.check!(ctx, path: path_with) }.not_to raise_error
  end

  it "ignores non-executable files and directories" do
    dir = Dir.mktmpdir
    File.write(File.join(dir, "yarn"), "")
    FileUtils.mkdir_p(File.join(dir, "node"))

    expect(described_class.available?("yarn", path: dir)).to be false
    expect(described_class.available?("node", path: dir)).to be false
  end
end
