# frozen_string_literal: true

require "yaml"
require "date"
require "json"
require "fileutils"
require "tempfile"
# Bundler.with_unbundled_env runs the generators outside this gem's own bundle; the constant is
# not loaded when the installed gem runs without `bundle exec`.
require "bundler"
require "thor"

# Templates and generated files contain non-ASCII (em dashes); a C/POSIX locale
# (CI, Docker) would otherwise make File.read raise on them.
Encoding.default_external = Encoding::UTF_8

require_relative "opinionated_rails/version"
require_relative "opinionated_rails/error"
require_relative "opinionated_rails/context"
require_relative "opinionated_rails/answer_shell"
require_relative "opinionated_rails/step"
require_relative "opinionated_rails/step_graph"
require_relative "opinionated_rails/manifest"
require_relative "opinionated_rails/rails_version_guard"
require_relative "opinionated_rails/prerequisites"
require_relative "opinionated_rails/kamal_config"
require_relative "opinionated_rails/cli"
require_relative "opinionated_rails/generators/rails_new_invoker"
require_relative "opinionated_rails/generators/file_writer"

Dir[File.expand_path("opinionated_rails/steps/**/*.rb", __dir__)].sort.each do |file|
  require file
end

module OpinionatedRails
  def self.step_classes
    [ Steps::Core, Steps::Addons ].flat_map do |mod|
      mod.constants.map { |name| mod.const_get(name) }
    end
  end
end
