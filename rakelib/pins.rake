# frozen_string_literal: true

namespace :pins do
  desc "Check every pinned gem/npm version exists on its registry and report newer ones"
  task :check do
    require_relative "../lib/opinionated_rails/pins"

    results = OpinionatedRails::Pins.check(OpinionatedRails::Pins.collect)
    results.each do |r|
      line = format("%-9s %-26s %-10s %s", r.status, r.pin.name, r.pin.version, r.status == :current ? "" : "latest #{r.latest}")
      puts line
    end

    missing = results.select { |r| r.status == :missing }
    outdated = results.count { |r| r.status == :outdated }
    puts "\n#{results.size} pins: #{missing.size} missing, #{outdated} outdated"
    abort "Pinned versions that no longer exist: #{missing.map { |r| "#{r.pin.name} #{r.pin.version}" }.join(', ')}" unless missing.empty?
  end
end
