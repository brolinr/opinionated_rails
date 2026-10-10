# frozen_string_literal: true

# A test shell that answers prompts by matching their text rather than by position, so specs
# keep working when steps are added or reordered. Unmatched prompts get "" (the default).
#
#   PromptShell.new("Test framework" => "RSpec", "VCR" => "yes")
class PromptShell
  MAX_REPEATS = 5

  attr_reader :messages, :prompts

  def initialize(answers = {})
    @answers = answers
    @messages = []
    @prompts = []
    @asked = Hash.new(0)
  end

  def ask(prompt = nil, *)
    text = prompt.to_s
    @prompts << text
    @asked[text] += 1
    raise "PromptShell: #{text.inspect} asked #{@asked[text]} times (invalid answer loop?)" if @asked[text] > MAX_REPEATS

    label = text.split("(default").first.downcase # keys match the label, not the default's text
    _, answer = @answers.find { |key, _| label.include?(key.downcase) }
    answer.to_s
  end

  def say(message, _color = nil)
    @messages << message
  end

  # Thor reports Thor::Error through the shell's #error.
  def error(message)
    $stderr.puts(message)
  end
end
