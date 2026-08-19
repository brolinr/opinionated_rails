# frozen_string_literal: true

require "thor"

module OpinionatedRails
  class CLI < Thor
    desc "new APP_NAME", "Generate a new Rails app"
    def new(_app_name)
      raise NotImplementedError, "OpinionatedRails::CLI#new not yet implemented"
    end

    desc "add STEP_ID", "Add a step to an existing app"
    def add(_step_id)
      raise NotImplementedError, "OpinionatedRails::CLI#add not yet implemented"
    end
  end
end
