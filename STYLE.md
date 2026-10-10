# Style Guide

The real conventions this codebase has converged on, not aspirational ones. If you're about to write a new step, copy the shape of an existing one in the same tier before inventing something new.

## Step shape

Every step (`lib/opinionated_rails/steps/{core,addons}/*.rb`) follows the same contract:

- `# frozen_string_literal: true` at the top of every file.
- Class methods: `self.id`, `self.tier`, `self.needs`, `self.summary`, `self.description`, `self.prompts`.
- Instance methods: `if_condition(context)`, `prompt(context)`, `generate(context)`, `outputs(context)`.
- `outputs(context)` is always just `context.output(:step_id)` — it reads back what `generate` already recorded via `context.set_output`.
- Steps with no prompt still define `prompt(context)` as a no-op (`def prompt(_context); end`) rather than omitting it.

## Idempotent `generate`

Every `generate` method must be safe to call twice against the same app without duplicating output. This matters because the planned `opinionated_rails add` command will run a step's `generate` against an app that already has that step's earlier output on disk, and because re-running a step must never corrupt an app. The established patterns:

- Gemfile edits check `content.include?(gem_line)` before appending, and use a find-or-create "insert before the matching group's closing `end`" helper for group-scoped gems (see `add_development_group_gem`/`add_top_level_gem`-style private helpers across the addon steps).
- Config file edits (`config/environments/*.rb`, `config/cable.yml`, `config/routes.rb`) look for a known anchor line/block and only insert if the target content isn't already present.
- Static file copies (`FileWriter`) overwrite deterministically — copying the same template twice produces the same file, not an error.

## Pinned versions

Every gem a step adds is pinned to an exact version (`gem "foo", "1.2.3"`), never a `~>`/`>=` range. When a pin goes stale (yanked/unavailable), fix it at the source — don't silently widen the constraint.

## `needs` has two different meanings — don't conflate them

1. **Ordering-only.** A step declares `needs: [:database, :frontend]` purely so `StepGraph` runs it after those steps' `generate` has produced real files/Gemfile entries on disk — the step itself never calls `context.output(:database, ...)`. `docker_kamal` is the canonical example: it needs accurate on-disk state for `dockerfile-rails`'s own app-inspection, not the actual output values.
2. **Real cross-step reads.** A step declares `needs: [:secrets_handling]` *and* actually branches on `context.output(:secrets_handling, :secrets_handling)` in its own `generate`. `mailer` is the canonical example — its Postmark config genuinely differs based on that value.

If a step only wants to *peek* at another step's output without requiring it as a hard dependency, don't add it to `needs` at all — read it defensively instead (see below).

## Soft/optional reads

Some steps read another step's output without declaring `needs` on it, because the read is optional and defaults gracefully when absent — e.g. `ci` reads `context.output(:js_lint, :js_lint) || false` to decide whether to add a JS-lint CI job, but doesn't require `js_lint` to have run first. Use this pattern instead of `needs` whenever a missing/skipped upstream step should just mean "skip this optional behavior," not "block this step entirely."

## Skipping Rails' own scaffolding (`--skip-*` precedent)

When an addon step wants to be the sole author of files `rails new` would otherwise generate on its own, pass the matching flag in `CLI#build_rails_new_flags` rather than fighting or overwriting Rails' defaults after the fact — see `--skip-docker`/`--skip-kamal` (for `docker_kamal_step`) and `--skip-ci` (for `ci_step`). This avoids "file already exists"/conflicting-gem-declaration problems entirely instead of working around them.

## Static templates

Verbatim, non-interpolated content — PR/issue templates, the RuboCop custom-overrides seed, the application service/result base classes — lives under `lib/opinionated_rails/templates/` and is copied byte-for-byte via `Generators::FileWriter`. Never hand-rebuild this kind of content inline in a step; if it needs to change, edit the template file.

## Specs

- Unit specs build isolated `Context`s (`Dir.mktmpdir` for `app_path`) and answer prompts with `PromptShell` (`spec/support/prompt_shell.rb`), keyed by prompt text (`PromptShell.new("Stack" => "redis")`); unlisted prompts take their default. Never feed answers positionally: reordering or adding a step silently shifts every answer after it. `TestShell` (an ordered array) is only for single-step unit specs.
- To test a step that reads another step's output, seed it directly with `context.set_output(:other_step, { ... })` in the spec rather than actually running the other step first.
- Integration specs are split into a fast, default-run suite (no real `bundle install`, no network — always pass `--skip-bundle-install`) and a slow, `integration: true`-tagged suite that's excluded by default and only runs with `RUN_INTEGRATION_SPECS=1`, since it does a real `bundle install` and runs real generators. Any step whose `generate` shells out to `bundle`/generators needs both: a fast spec asserting the Gemfile/skip-guard behavior, and (for anything non-trivial) a slow spec proving the real generator actually works end to end.
- The slow suite (`spec/opinionated_rails/integration/generated_apps_slow_spec.rb`) generates real apps and asserts they are *healthy* via `expect_healthy` (`spec/support/generated_app.rb`): the bundle resolves, the app boots and eager-loads in development, production and staging, and its own RuboCop, Brakeman and bundler-audit pass. String assertions on generated files are not enough: a step can write exactly the expected text and still produce an app that cannot boot (the Pagy and Redis cleanup bugs both did). When you add or change a step, add the combination to this suite.
- Anything a generator we don't own emits (Devise, dockerfile-rails, Rails' own generators) can be broken or style-noncompliant for some option combinations; treat generated output as untrusted until the slow suite boots it.
- When shelling out to `bundle`/`rails generate`/other bundler-aware commands from within a step, wrap the call in `Bundler.with_unbundled_env` and run `bundle install --quiet` first — otherwise the outer `opinionated_rails` process's own `BUNDLE_GEMFILE`/lockfile leaks into the generated app's shell-out and it silently resolves against the wrong Gemfile.
