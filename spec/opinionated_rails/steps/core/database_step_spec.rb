# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Core::DatabaseStep do
  let(:shell_class) do
    Class.new do
      attr_reader :messages, :answers

      def initialize(answers)
        @answers = answers.dup
        @messages = []
      end

      def ask(_prompt = nil)
        @answers.shift
      end

      def say(message, _color = nil)
        @messages << message
      end
    end
  end

  def build_context(answers)
    OpinionatedRails::Context.new(app_path: "/tmp", shell: shell_class.new(answers))
  end

  it "has the expected id, tier, and prompts" do
    expect(described_class.id).to eq(:database)
    expect(described_class.tier).to eq(:core)
    expect(described_class.prompts).to be_a(String)
  end

  it "defaults to SQLite" do
    ctx = build_context([ "" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:database)).to eq(:sqlite3)
  end

  it "accepts 'postgresql'" do
    ctx = build_context([ "PostgreSQL" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:database)).to eq(:postgresql)
  end

  it "accepts 'mysql'" do
    ctx = build_context([ "MySQL" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:database)).to eq(:mysql2)
  end

  it "rejects invalid choices and keeps asking" do
    ctx = build_context([ "oracle", "mysql" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:database)).to eq(:mysql2)
  end

  it "generates the expected output" do
    ctx = build_context([ "PostgreSQL" ])
    described_class.new.prompt(ctx)
    described_class.new.generate(ctx)
    expect(ctx.output(:database)).to eq({ database: :postgresql })
  end

  it "returns the output" do
    ctx = build_context([ "MySQL" ])
    described_class.new.prompt(ctx)
    described_class.new.generate(ctx)
    expect(described_class.new.outputs(ctx)).to eq({ database: :mysql2 })
  end
end
