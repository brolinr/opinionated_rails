# frozen_string_literal: true

require "spec_helper"

# AnswerShell::CHOICES is validated up front; every choice it lists must really be accepted by the
# step that asks for it, or a documented config value would fail halfway through a run.
RSpec.describe "AnswerShell choices" do
  def prompt_all_steps(answers)
    shell = OpinionatedRails::AnswerShell.new(PromptShell.new, answers: answers, yes: true)
    Dir.mktmpdir do |tmp|
      ctx = OpinionatedRails::Context.new(app_path: tmp, shell: shell)
      # Make conditional prompts (bundler, factory, js_lint) reachable.
      ctx.set_output(:frontend, { frontend: :react })
      ctx.set_output(:testing, { test_framework: :rspec })
      ctx.set_output(:app_type, { app_type: :full_stack })
      ctx.answer(:frontend, :react)
      ctx.answer(:testing, :rspec)
      steps = [ OpinionatedRails::Steps::Core::AppTypeStep, OpinionatedRails::Steps::Core::DatabaseStep,
                OpinionatedRails::Steps::Core::TestingStep, OpinionatedRails::Steps::Core::FrontendStep ] +
              OpinionatedRails::CLI.generated_steps
      steps.uniq.each do |klass|
        step = klass.new
        step.prompt(ctx) if step.if_condition(ctx)
      end
    end
    shell
  end

  OpinionatedRails::AnswerShell::CHOICES.each do |key, values|
    values.each do |value|
      it "#{key}: #{value} is accepted by its step" do
        answers = { key => value }
        answers["frontend"] = "react" if key == "bundler" # the bundler is only asked for React
        shell = prompt_all_steps(answers)

        expect(shell.used[key]).to eq(1), "no prompt consumed #{key}: #{value}"
      end
    end
  end

  it "has a label for every choice key" do
    expect(OpinionatedRails::AnswerShell::CHOICES.keys - OpinionatedRails::AnswerShell::LABELS.keys).to eq([])
  end
end
