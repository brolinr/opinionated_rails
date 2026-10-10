# Contributing

Read `STYLE.md` before making any changes — it documents the conventions this codebase has actually converged on.

## Core vs. addon steps

`Steps::Core` (`app_name`, `database`, `app_type`, `testing`, `frontend`) exists as a separate tier for a structural reason, not a stylistic one: `CLI#new` prompts and sequences these steps itself, before `rails new` even runs, and every addon step's `needs` array is declared against these ids (e.g. `docker_kamal` needs `:database`/`:frontend`, `ci` needs `:testing`, `mailer` needs `:secrets_handling`). Addon steps run afterward, ordered by `StepGraph`.

**A new step only belongs in `Steps::Core` if something structurally depends on it running before `rails new`.** If it just needs to run after another step (addon or core) has already generated files, express that with `needs` and let it live in `Steps::Addons` — don't move it to Core just because it feels important.

When in doubt: if you're adding a new step and you're not sure which tier it goes in, it's almost certainly `Steps::Addons`.

## Checklist for adding or changing an option

1. **The step**: follow `STYLE.md` (contract, idempotent `generate`, pinned versions). Pin every new gem or npm package exactly; `bundle exec rake pins:check` must still pass (add a new `*_VERSION` constant's gem name to `Pins::GEM_NAMES`).
2. **Non-interactive use**: add its prompt label and accepted values to `AnswerShell::LABELS` and `AnswerShell::CHOICES`. `answer_choices_spec.rb` fails if a listed value is not accepted by the step.
3. **Unit specs** for the step, including idempotency and an invalid-input case.
4. **A real-app combo**: add `spec/fixtures/combos/<name>.yml` (and its assertions in `generated_apps_slow_spec.rb`), then run `RUN_INTEGRATION_SPECS=1 bundle exec rspec spec/opinionated_rails/integration/generated_apps_slow_spec.rb -e "<name>"`. The app must boot in development, production and staging and pass its own RuboCop, Brakeman, bundler-audit and tests; add the combo to the matrix in `.github/workflows/ci.yml`.
5. **Docs**: README option table and `CHANGELOG.md`.

Never edit Rails-generated text with a bare string substitution that can silently do nothing: warn through `context.shell.say("Warning: ...")` with the exact setting to apply by hand when an anchor is missing.
