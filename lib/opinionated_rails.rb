# frozen_string_literal: true

require "yaml"
require "fileutils"
require "tempfile"

require_relative "opinionated_rails/version"
require_relative "opinionated_rails/error"
require_relative "opinionated_rails/context"
require_relative "opinionated_rails/step"
require_relative "opinionated_rails/step_graph"
require_relative "opinionated_rails/manifest"
require_relative "opinionated_rails/rails_version_guard"
require_relative "opinionated_rails/cli"
require_relative "opinionated_rails/generators/rails_new_invoker"
require_relative "opinionated_rails/generators/file_writer"

Dir[File.expand_path("opinionated_rails/steps/**/*.rb", __dir__)].sort.each do |file|
  require file
end

module OpinionatedRails
  def self.register_step(_step_class)
    # v1.1+ plugin hook. No-op in v1.
  end

  def self.step_classes
    [ Steps::Core, Steps::Addons ].flat_map do |mod|
      mod.constants.map { |name| mod.const_get(name) }
    end
  end
end
