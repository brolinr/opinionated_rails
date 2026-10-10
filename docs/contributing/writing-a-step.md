---
title: Writing a step
parent: Contributing
nav_order: 2
---

# Writing a step
{: .no_toc }

1. TOC
{:toc}

## The contract

Every step (`lib/opinionated_rails/steps/{core,addons}/*.rb`) follows the same shape:

```ruby
# frozen_string_literal: true

module OpinionatedRails
  module Steps
    module Addons
      class ExampleStep < Step
        def self.id = :example
        def self.tier = :addon
        def self.needs = []
        def self.summary = "Configure Example"
        def self.description = "One sentence on what it adds."
        def self.prompts = "Enable Example? (default: no)"

        EXAMPLE_VERSION = "1.2.3".freeze

        def if_condition(_context) = true

        def prompt(context)
          shell = context.shell
          choice = shell.ask("Enable Example? (default: no):").to_s.strip
          choice = "no" if choice.empty?

          loop do
            case choice.downcase
            when "yes", "y" then context.answer(:example, true); break
            when "no", "n" then context.answer(:example, false); break
            else
              shell.say("Invalid. Enter 'yes' or 'no'.", :red)
              choice = shell.ask("Enable Example? (default: no):").to_s.strip
              choice = "no" if choice.empty? # a re-ask must also fall back to the default
            end
          end
        end

        def generate(context)
          enabled = context.get(:example) == true
          # edit the generated app here
          context.set_output(:example, { example: enabled })
        end

        def outputs(context) = context.output(:example)
      end
    end
  end
end
```

Rules the code and specs rely on:

- `outputs(context)` just reads back `context.output(:step_id)`.
- A step with no question still defines `prompt` as a no-op.
- **Re-asks fall back to the default.** After an invalid answer, an empty reply (or end of input) must take the default, or the loop never ends. `prompt_resilience_spec.rb` fails any step that violates this.
- **Pin exact versions** in `*_VERSION` constants.
- **`generate` is idempotent**: running it twice must not duplicate output. Check before appending to files; use the group-aware Gemfile helpers the other steps use.
- **Respect `skip_bundle_install`**: when true, only write files and Gemfile lines; do not shell out to `bundle`, generators or `yarn`.
- **Shell out safely**: `Bundler.with_unbundled_env { system("cmd", "arg") }` (argument array, never a string), run from the app directory, and raise `OpinionatedRails::Error` on failure.
- **Never silently skip an edit** to Rails' files. Warn with the exact setting to apply by hand.

## `needs` has two meanings

1. **Ordering only.** `ci` needs `rubocop` and `testing` so those have run first.
2. **A real read.** `mailer` needs `secrets_handling` *and* branches on `context.output(:secrets_handling, :secrets_handling)`.

If a step only wants to peek at another step's output, do not add it to `needs`: read it defensively (`context.output(:js_lint, :js_lint) || false`), so a skipped upstream step just means "skip the optional behavior". Keep `needs` honest: staging needs `solid_stack`, `mailer` and `docker_kamal` because it copies files those steps edit.

## Skipping Rails' own files

If a step should be the only author of files `rails new` would otherwise create, pass the matching flag in `CLI#build_rails_new_flags` (see `--skip-docker`, `--skip-kamal`, `--skip-ci`) instead of overwriting afterwards.

## Static templates

Verbatim content (PR templates, service base classes, the generated `STYLE.md`) lives in `lib/opinionated_rails/templates/` and is copied with `Generators::FileWriter`. Edit the template file; do not rebuild it inline. Generated Ruby must pass the *generated app's* RuboCop (templates are excluded from this repo's lint, so check by generating).

## Checklist for adding or changing an option

1. **The step**, following the rules above. Pin every new gem or npm package exactly; `bundle exec rake pins:check` must pass (map a new `*_VERSION` constant to its gem name in `Pins::GEM_NAMES`).
2. **Non-interactive use.** Add its prompt label to `AnswerShell::LABELS` and its accepted values to `AnswerShell::CHOICES`. `answer_choices_spec.rb` fails if a listed value is not accepted by the step.
3. **Unit specs** for the step: the default path, each choice, idempotency, an invalid answer.
4. **A real-app combo.** Add `spec/fixtures/combos/<name>.yml` and its assertions in `generated_apps_slow_spec.rb`, run it (see [Testing](testing.html)), and add it to the matrix in `.github/workflows/ci.yml`.
5. **Docs.** Add it to [Options](../options.html) and [Config file](../config-file.html), then run `bundle exec rake docs:steps` to refresh the [step reference](../steps.html). `docs_spec.rb` fails if the docs and code disagree.
6. `CHANGELOG.md`.
