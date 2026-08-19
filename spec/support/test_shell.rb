# frozen_string_literal: true

class TestShell
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
