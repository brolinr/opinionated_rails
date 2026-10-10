# frozen_string_literal: true

require "spec_helper"
require "timeout"

# A prompt that loops until it gets valid input must still terminate when the input is
# empty or the stream has ended (piped stdin, CI), by falling back to its documented default.
RSpec.describe "prompt resilience" do
  class StubbornShell
    def initialize = @asked = 0

    def ask(_prompt = nil, *)
      @asked += 1
      @asked == 1 ? "definitely-not-valid" : ""
    end

    def say(_message, _color = nil); end
  end

  prompting_steps = OpinionatedRails::CLI.generated_steps.reject do |step_class|
    # app_name has no default; database re-prompts with its own default each iteration.
    [ :app_name ].include?(step_class.id)
  end

  prompting_steps.each do |step_class|
    it "#{step_class.id} terminates after an invalid answer followed by an empty one" do
      Dir.mktmpdir do |tmp|
        ctx = OpinionatedRails::Context.new(app_path: tmp, shell: StubbornShell.new)
        ctx.set_output(:frontend, { frontend: :react }) # makes conditional prompts reachable
        step = step_class.new

        Timeout.timeout(2) { step.prompt(ctx) if step.if_condition(ctx) }
      end
    end
  end
end
