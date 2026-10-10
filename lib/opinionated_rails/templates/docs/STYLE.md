# Project Style Guide

Conventions for this codebase. Follow the shape of existing code before inventing something new.

## General

- Ruby style is enforced by RuboCop. Run `bin/rubocop` (add `-a` to autocorrect) before committing. Do not disable cops inline without a comment explaining why.
- Keep controllers thin: parse params, call one object, render or redirect. Put business rules in models or services.
- Prefer small, named methods over long ones. Comment the *why*, not the *what*.

## Services (if `app/services` exists)

- Services inherit from `ApplicationService`, expose a single public `call`, and return a `Result`.
- Call them as `MyService.call(...)`. Check `result.success?` / `result.failure?`; read `result.data` and `result.errors`.
- Wrap multi-record writes in `transaction { ... }`. Add an error to the result to roll back.
- Services must not render, redirect or touch `params`. Pass plain arguments in.

## Models and database

- Add database constraints (null, unique, foreign keys) and indexes in the migration, not only validations in the model.
- Never edit a migration that has been merged. Add a new one.
- Avoid N+1 queries: use `includes`/`preload` when iterating associations.

## Testing

- Every behaviour change ships with a test. Fix a bug by writing the failing test first.
- Keep tests independent and deterministic. Do not hit real external services; stub or record them.
- Run the full suite and `bin/rubocop` before opening a pull request.

## Security

- Never commit secrets. Use Rails credentials (`bin/rails credentials:edit`) or environment variables, and keep `.env*` files out of git.
- Always use strong parameters. Never build SQL with string interpolation.
- Run `bin/brakeman` and `bin/bundler-audit` regularly. CI should fail on new warnings.

## Git and pull requests

- Small, focused commits with imperative-mood messages ("Add invoice export").
- Pull requests describe the problem, the approach and how it was verified.
