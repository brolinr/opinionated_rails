# frozen_string_literal: true

require "thor"

module OpinionatedRails
  class CLI < Thor
    class UnknownStepError < Thor::Error; end

    desc "new APP_NAME", "Generate a new Rails app"
    def new(_app_name)
      raise NotImplementedError, "OpinionatedRails::CLI#new not yet implemented"
    end

    desc "add STEP_ID", "Add a step to an existing app"
    def add(_step_id)
      raise NotImplementedError, "OpinionatedRails::CLI#add not yet implemented"
    end

    desc "list", "List all supported steps"
    method_option :tier, type: :string, enum: %w[ core addon ], desc: "Filter by tier"
    def list
      steps = step_classes
      steps = steps.select { |step_class| step_class.tier.to_s == options[:tier] } if options[:tier]

      steps.each do |step_class|
        puts "#{step_class.id} (#{step_class.tier}) — #{step_class.summary}"
      end
    end

    desc "info STEP_ID", "Show details for a step"
    def info(step_id)
      step_id = step_id.to_sym
      step_class = step_classes.find { |klass| klass.id == step_id }
      raise UnknownStepError, "Unknown step: #{step_id.inspect}" unless step_class

      puts "id:          #{step_class.id}"
      puts "tier:        #{step_class.tier}"
      puts "summary:     #{step_class.summary}"
      puts "description: #{step_class.description}"
      puts "needs:       #{format_needs(step_class)}"
      puts "prompts for: #{format_prompts(step_class)}"
      puts "outputs:     #{safe_outputs(step_class)}"
    end

    private

    def step_classes
      OpinionatedRails.step_classes
    end

    def format_needs(step_class)
      return "none" if step_class.needs.empty?

      step_class.needs.join(", ")
    end

    def format_prompts(step_class)
      step_class.respond_to?(:prompts) ? step_class.prompts : "not yet implemented"
    end

    def safe_outputs(step_class)
      step = step_class.new
      step.outputs(OpinionatedRails::Context.new(app_path: Dir.pwd))
    rescue NotImplementedError
      "not yet implemented"
    end
  end
end
