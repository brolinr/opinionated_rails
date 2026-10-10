# frozen_string_literal: true

require "yaml"
require "date"
require "fileutils"

module OpinionatedRails
  class Manifest
    FILENAME = ".opinionated_rails.yml"
    VERSION = "0.1.0"

    def self.load(app_path)
      path = File.join(app_path, FILENAME)
      data = File.exist?(path) ? YAML.safe_load_file(path, permitted_classes: [ Date, DateTime, Time ], aliases: true) || {} : {}
      new(app_path, data)
    end

    def initialize(app_path, data)
      @app_path = app_path
      @data = data
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      @data[key] = value
    end

    def to_h
      @data.dup
    end

    def write
      path = File.join(@app_path, FILENAME)
      tmp = "#{path}.tmp.#{Process.pid}"
      File.write(tmp, YAML.dump(@data))
      File.rename(tmp, path)
    end
  end
end
