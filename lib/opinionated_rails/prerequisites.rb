# frozen_string_literal: true

module OpinionatedRails
  # Tools the chosen options shell out to. Checked before `rails new` so a missing tool fails
  # fast with instructions, rather than leaving a half-built app (jsbundling-rails, for example,
  # silently skips `yarn add esbuild` when yarn is absent).
  module Prerequisites
    INSTALL_HINTS = {
      "node" => "install Node.js (https://nodejs.org)",
      "yarn" => "enable it with `corepack enable` or install it with `npm install -g yarn`",
      "bun" => "install it from https://bun.sh"
    }.freeze

    def self.required_tools(context)
      return [] unless context.get(:frontend) == :react

      context.get(:bundler) == :bun ? %w[ bun ] : %w[ node yarn ]
    end

    def self.available?(tool, path: ENV.fetch("PATH", ""))
      path.split(File::PATH_SEPARATOR).any? do |dir|
        candidate = File.join(dir, tool)
        File.file?(candidate) && File.executable?(candidate)
      end
    end

    def self.check!(context, path: ENV.fetch("PATH", ""))
      return if context.skip_bundle_install

      missing = required_tools(context).reject { |tool| available?(tool, path: path) }
      return if missing.empty?

      details = missing.map { |tool| "  - #{tool}: #{INSTALL_HINTS.fetch(tool)}" }.join("\n")
      raise OpinionatedRails::Error,
            "The React frontend needs tools that are not on your PATH:\n#{details}\n" \
            "Install them and re-run, or pass --skip-bundle-install to only scaffold files."
    end
  end
end
