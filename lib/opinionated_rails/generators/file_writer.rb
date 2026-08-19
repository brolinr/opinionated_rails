# frozen_string_literal: true

require "fileutils"

module OpinionatedRails
  module Generators
    class FileWriter
      def write(path, content)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
      end

      def render(_template_path, _locals = {})
        raise NotImplementedError, "OpinionatedRails::Generators::FileWriter#render not yet implemented"
      end
    end
  end
end
