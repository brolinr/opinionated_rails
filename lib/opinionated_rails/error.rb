# frozen_string_literal: true

module OpinionatedRails
  # Thor::Error makes the CLI print the message and exit non-zero instead of dumping a backtrace.
  class Error < Thor::Error; end
end
