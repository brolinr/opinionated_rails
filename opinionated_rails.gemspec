# frozen_string_literal: true

require_relative "lib/opinionated_rails/version"

Gem::Specification.new do |spec|
  spec.name = "opinionated_rails"
  spec.version = OpinionatedRails::VERSION
  spec.authors = [ "brolinr" ]
  spec.email = [ "remunyangabrolin@gmail.com" ]

  spec.summary = "Opinionated, interactive Rails starter generator"
  spec.description = "Generates Rails applications by composing independent, opinionated steps."
  spec.homepage = "https://github.com/brolinr/opinionated_rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = (Dir.glob("lib/**/*", File::FNM_DOTMATCH) + Dir.glob("exe/*") + %w[ README.md LICENSE.txt CHANGELOG.md ])
                   .reject { |f| File.directory?(f) }
  spec.bindir = "exe"
  spec.executables = [ "opinionated_rails" ]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "thor", "~> 1.3"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-rails-omakase", "~> 1.0"
end
