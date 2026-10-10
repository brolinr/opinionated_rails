# frozen_string_literal: true

require "fileutils"

module OpinionatedRails
  module Generators
    class FileWriter
      def write(path, content)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
      end
    end
  end
end
