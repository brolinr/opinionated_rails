# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpinionatedRails::StepGraph do
  let(:fake_base) do
    Class.new(OpinionatedRails::Step) do
      class << self
        attr_accessor :step_id, :step_needs
      end

      def self.id = step_id
      def self.needs = step_needs
    end
  end

  def step(id, needs: [])
    Class.new(fake_base) do
      self.step_id = id
      self.step_needs = needs
    end.new
  end

  describe "#sorted" do
    it "returns steps in topological order" do
      a = step(:a)
      b = step(:b, needs: [ :a ])
      c = step(:c, needs: [ :b ])
      graph = described_class.new([ c, a, b ])
      expect(graph.sorted.map { |s| s.class.id }).to eq([ :a, :b, :c ])
    end

    it "raises MissingDependencyError when a needed step is not registered" do
      a = step(:a, needs: [ :missing ])
      graph = described_class.new([ a ])
      expect { graph.sorted }.to raise_error(
        described_class::MissingDependencyError,
        /:missing/
      )
    end

    it "raises CycleError for a direct two-node cycle and names both steps" do
      a = step(:a, needs: [ :b ])
      b = step(:b, needs: [ :a ])
      graph = described_class.new([ a, b ])
      expect { graph.sorted }.to raise_error(described_class::CycleError) do |error|
        expect(error.message).to match(/:a/)
        expect(error.message).to match(/:b/)
      end
    end

    it "raises CycleError for a longer cycle and names every step in the loop" do
      a = step(:a, needs: [ :b ])
      b = step(:b, needs: [ :c ])
      c = step(:c, needs: [ :a ])
      graph = described_class.new([ a, b, c ])
      expect { graph.sorted }.to raise_error(described_class::CycleError) do |error|
        expect(error.message).to match(/:a/)
        expect(error.message).to match(/:b/)
        expect(error.message).to match(/:c/)
      end
    end
  end
end
