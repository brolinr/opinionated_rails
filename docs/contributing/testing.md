---
title: Testing
parent: Contributing
nav_order: 3
---

# Testing
{: .no_toc }

<details markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

## The two suites

```bash
bundle exec rspec                          # fast suite: seconds, offline after setup
RUN_INTEGRATION_SPECS=1 bundle exec rspec  # also the real-app matrix: minutes, needs network
bundle exec rubocop
```

**Fast suite.** Unit specs per step, plus integration specs that run a real `rails new --skip-bundle` into a temp directory (so Rails must be installed) and assert on the generated files. It also builds the gem, installs it into an isolated gem home and runs it (`packaging_spec.rb`), so a file missing from the package fails here, not after publishing.

**Real-app matrix** (`spec/opinionated_rails/integration/generated_apps_slow_spec.rb`, tagged `integration: true`). It generates a real app, with real installs, for every file in `spec/fixtures/combos/` and checks it is healthy.

## Prompts in specs

Never feed answers positionally: adding or reordering a step silently shifts every later answer. Use `PromptShell` (`spec/support/prompt_shell.rb`), keyed by prompt label:

```ruby
shell = PromptShell.new("Stack" => "redis", "Test framework" => "RSpec")
```

Unlisted prompts take their default, and it raises if a prompt repeats (a loop). `TestShell`, an ordered array, is only for single-step unit specs.

For CLI-level specs, use flags and config files instead (`cli_new_options_spec.rb`).

## The real-app matrix

Each combo is a [config file](../config-file.html). `expect_healthy` (`spec/support/generated_app.rb`) requires every generated app to:

| Check | Why |
| --- | --- |
| `bundle check` | The bundle is complete |
| Boot and eager-load in development, production and staging | Development autoloading hides missing constants; eager loading finds them |
| `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit` | The app is clean on day one |
| `bin/kamal config` | `deploy.yml` is valid (when Kamal is on) |
| The generated CI workflow's own `test` job steps, from a clean checkout (build output deleted) | If the CI file is wrong, the matrix fails |
| `/up` is 200 and `/` is not a server error, through Rack | The app serves requests |

Per-combo extras live in the `EXTRA` table in the spec, for example that the Redis combo has no Solid gems and refuses to boot in production without `REDIS_URL`.

### Running it

```bash
# everything this machine can run
RUN_INTEGRATION_SPECS=1 bundle exec rspec spec/opinionated_rails/integration/generated_apps_slow_spec.rb

# one combo
RUN_INTEGRATION_SPECS=1 bundle exec rspec spec/opinionated_rails/integration/generated_apps_slow_spec.rb -e "react_webpack"
```

A combo whose tools are missing is **skipped, not failed**: React needs `yarn` (or `bun`), MySQL needs a reachable server. PostgreSQL combos run their tests only if `pg_isready` succeeds; otherwise they still boot and lint but skip the database-backed test run. The tool's own spec output says what was skipped.

Without yarn installed globally you can use a scratch shim:

```bash
mkdir -p /tmp/yarnbin && corepack enable --install-directory /tmp/yarnbin yarn
PATH=/tmp/yarnbin:$PATH RUN_INTEGRATION_SPECS=1 bundle exec rspec ...
```

Generated apps are left in your system temp directory, which is useful for debugging a failure.

## CI

`.github/workflows/ci.yml` runs:

| Job | When | What |
| --- | --- | --- |
| `test` | every push and pull request | fast suite on Ruby 3.2, 3.3, 3.4 |
| `lint` | same | RuboCop |
| `audit` | same | bundler-audit |
| `pins` | same | `rake pins:check`: every pinned version still exists |
| `generated-apps` | pushes to `main`, nightly, manual | one job per combo, with PostgreSQL, MySQL and Redis services, Node, yarn and bun |

The gem does not commit a `Gemfile.lock`, so each Ruby resolves its own dependency versions.

## Writing a good test

- Test behavior that could break the generated app, not that a string was written. If the only way to know it works is to boot the app, add or extend a combo.
- Assert idempotency for anything that edits files.
- For a bug found by a combo, add a unit spec that pins the cause *and* keep the combo.
- When Rails text is edited, test both the matched case and the warning when it is missing.
