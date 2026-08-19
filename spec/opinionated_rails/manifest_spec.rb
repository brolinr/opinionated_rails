# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe OpinionatedRails::Manifest do
  let(:tmp) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(tmp)
  end

  it "writes and loads data" do
    manifest = described_class.new(tmp, { "app_name" => "myapp" })
    manifest.write
    loaded = described_class.load(tmp)
    expect(loaded["app_name"]).to eq("myapp")
  end

  it "creates an empty manifest when the file does not exist" do
    manifest = described_class.load(tmp)
    expect(manifest.to_h).to eq({})
  end

  it "updates values" do
    manifest = described_class.new(tmp, { "foo" => 1 })
    manifest["foo"] = 2
    expect(manifest["foo"]).to eq(2)
  end
end
