# Contributing

Read `STYLE.md` before making any changes — it documents the conventions this codebase has actually converged on.

## Core vs. addon steps

`Steps::Core` (`app_name`, `database`, `app_type`, `testing`, `frontend`) exists as a separate tier for a structural reason, not a stylistic one: `CLI#new` prompts and sequences these steps itself, before `rails new` even runs, and every addon step's `needs` array is declared against these ids (e.g. `docker_kamal` needs `:database`/`:frontend`, `ci` needs `:testing`, `mailer` needs `:secrets_handling`). Addon steps run afterward, ordered by `StepGraph`.

**A new step only belongs in `Steps::Core` if something structurally depends on it running before `rails new`.** If it just needs to run after another step (addon or core) has already generated files, express that with `needs` and let it live in `Steps::Addons` — don't move it to Core just because it feels important.

When in doubt: if you're adding a new step and you're not sure which tier it goes in, it's almost certainly `Steps::Addons`.
