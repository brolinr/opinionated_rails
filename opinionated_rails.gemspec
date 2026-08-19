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
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/])
    end
  end
  spec.bindir = "exe"
  spec.executables = [ "opinionated_rails" ]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "thor", "~> 1.3"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-rails-omakase", "~> 1.0"
end
