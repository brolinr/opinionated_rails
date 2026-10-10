# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::Steps::Core::AppNameStep do
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
    expect(described_class.id).to eq(:app_name)
    expect(described_class.tier).to eq(:core)
    expect(described_class.prompts).to be_a(String)
  end

  it "normalizes and validates a valid name" do
    ctx = build_context([ "My-App" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:app_name)).to eq("my_app")
  end

  it "rejects invalid names and keeps asking" do
    ctx = build_context([ "", "123bad", "my_app" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:app_name)).to eq("my_app")
    expect(ctx.shell.messages.first).to match(/Invalid:/)
  end

  it "rejects reserved and constant-colliding names" do
    ctx = build_context([ "test", "String", "my_app" ])
    described_class.new.prompt(ctx)
    expect(ctx.get(:app_name)).to eq("my_app")
  end

  it "generates the expected output" do
    ctx = build_context([ "my_app" ])
    described_class.new.prompt(ctx)
    described_class.new.generate(ctx)
    expect(ctx.output(:app_name)).to eq({ app_name: "my_app" })
  end

  it "returns the output" do
    ctx = build_context([ "my_app" ])
    described_class.new.prompt(ctx)
    described_class.new.generate(ctx)
    expect(described_class.new.outputs(ctx)).to eq({ app_name: "my_app" })
  end
  describe "non-interactive use" do
    it "raises instead of looping forever when input ends" do
      ctx = build_context([])

      expect { described_class.new.prompt(ctx) }.to raise_error(OpinionatedRails::Error, /input ended/)
    end

    it "uses a name given on the command line without asking" do
      ctx = build_context([])
      ctx.answer(:app_name_input, "My-App")
      described_class.new.prompt(ctx)

      expect(ctx.get(:app_name)).to eq("my_app")
    end

    it "asks when the name given on the command line is invalid" do
      ctx = build_context([ "good_app" ])
      ctx.answer(:app_name_input, "9bad")
      described_class.new.prompt(ctx)

      expect(ctx.get(:app_name)).to eq("good_app")
    end
  end
end
