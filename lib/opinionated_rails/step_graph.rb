# frozen_string_literal: true

module OpinionatedRails
  class StepGraph
    class Error < OpinionatedRails::Error; end
    class CycleError < Error; end
    class MissingDependencyError < Error; end

    def initialize(steps)
      @steps = steps
      @by_id = steps.to_h { |step| [ step.class.id, step ] }
    end

    def sorted
      @by_id.each_value do |step|
        step.class.needs.each do |needed|
          raise MissingDependencyError, "Step #{step.class.id.inspect} needs #{needed.inspect}, which is not registered" unless @by_id.key?(needed)
        end
      end

      in_degree = Hash.new(0)
      @by_id.each_key { |id| in_degree[id] = 0 }
      dependents = Hash.new { |h, k| h[k] = [] }

      @by_id.each_value do |step|
        step.class.needs.each do |needed|
          dependents[needed] << step.class.id
          in_degree[step.class.id] += 1
        end
      end

      queue = in_degree.select { |_, v| v.zero? }.keys
      result = []

      until queue.empty?
        id = queue.shift
        result << @by_id[id]

        dependents[id].each do |dependent|
          in_degree[dependent] -= 1
          queue << dependent if in_degree[dependent].zero?
        end
      end

      if result.size != @by_id.size
        remaining = in_degree.reject { |_, v| v.zero? }.keys
        raise CycleError, "Cyclic step dependencies detected among: #{remaining.map(&:inspect).join(', ')}"
      end

      result
    end
  end
end
