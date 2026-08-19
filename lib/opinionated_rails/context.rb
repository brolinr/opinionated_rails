# frozen_string_literal: true

require "thor"

module OpinionatedRails
  class Context
    attr_reader :app_path, :answers, :outputs
    attr_accessor :shell

    def initialize(app_path:, shell: Thor::Shell::Basic.new)
      @app_path = app_path
      @answers = {}
      @outputs = {}
      @shell = shell
    end

    def answer(key, value)
      @answers[key] = value
    end

    def get(key)
      @answers[key]
    end

    def selected?(step_id)
      !!@answers[step_id]
    end

    def set_output(step_id, data)
      @outputs[step_id] = data
    end

    def output(step_id, key = nil)
      step = @outputs.fetch(step_id, {})
      key ? step[key] : step
    end
  end
end
