# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Context do
  let(:context) { described_class.new(app_path: "/tmp/myapp") }

  it "stores and retrieves answers" do
    context.answer(:app_name, "myapp")
    expect(context.get(:app_name)).to eq("myapp")
    expect(context.selected?(:app_name)).to be true
  end

  it "stores and retrieves outputs" do
    context.set_output(:app_type, { mode: :api_only })
    expect(context.output(:app_type, :mode)).to eq(:api_only)
    expect(context.output(:app_type)).to eq({ mode: :api_only })
  end

  it "defaults to a Thor shell" do
    expect(context.shell).to be_a(Thor::Shell::Basic)
  end

  it "accepts an injected shell" do
    shell = Object.new
    ctx = described_class.new(app_path: "/tmp", shell: shell)
    expect(ctx.shell).to be(shell)
  end

  it "has a settable app_path" do
    context.app_path = "/tmp/renamed"
    expect(context.app_path).to eq("/tmp/renamed")
  end

  it "has a settable skip_bundle_install" do
    context.skip_bundle_install = true
    expect(context.skip_bundle_install).to be true
  end
end
