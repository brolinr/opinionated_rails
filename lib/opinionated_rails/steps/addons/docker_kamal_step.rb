# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class DockerKamalStep < Step
        def self.id = :docker_kamal
        def self.summary = "Configure Docker and Kamal"
        def self.description = "Generates a Dockerfile and optional Kamal deployment files."
      end
    end
  end
end
