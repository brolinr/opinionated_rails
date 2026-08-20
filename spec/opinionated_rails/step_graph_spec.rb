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

    it "orders frontend-dependent addons after the frontend step" do
      selected = [
        OpinionatedRails::Steps::Addons::JsLintStep,
        OpinionatedRails::Steps::Addons::DocsStep,
        OpinionatedRails::Steps::Addons::SpaControllerStep,
        OpinionatedRails::Steps::Addons::TailwindStep,
        OpinionatedRails::Steps::Core::FrontendStep,
        OpinionatedRails::Steps::Core::TestingStep
      ].map(&:new)

      ids = described_class.new(selected).sorted.map { |s| s.class.id }
      expect(ids.index(:frontend)).to be < ids.index(:js_lint)
      expect(ids.index(:frontend)).to be < ids.index(:spa_controller)
      expect(ids.index(:frontend)).to be < ids.index(:tailwind)
    end

    it "orders testing-dependent addons after the testing step" do
      selected = [
        OpinionatedRails::Steps::Addons::FactoryOrFixturesStep,
        OpinionatedRails::Steps::Addons::VcrStep,
        OpinionatedRails::Steps::Core::TestingStep,
        OpinionatedRails::Steps::Core::FrontendStep
      ].map(&:new)

      ids = described_class.new(selected).sorted.map { |s| s.class.id }
      expect(ids.index(:testing)).to be < ids.index(:factory_or_fixtures)
      expect(ids.index(:testing)).to be < ids.index(:vcr)
    end

    it "runs zero-dependency mechanical addons alongside docs, independent of testing/frontend" do
      selected = [
        OpinionatedRails::Steps::Addons::RubocopStep,
        OpinionatedRails::Steps::Addons::FakerStep,
        OpinionatedRails::Steps::Addons::PrIssueTemplatesStep,
        OpinionatedRails::Steps::Core::TestingStep,
        OpinionatedRails::Steps::Core::FrontendStep
      ].map(&:new)

      ids = described_class.new(selected).sorted.map { |s| s.class.id }
      expect(ids).to include(:rubocop, :faker, :pr_issue_templates)
    end
  end
end
