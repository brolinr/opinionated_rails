# Changelog

## 0.1.0 (unreleased)

First release.

- `opinionated_rails new [APP_NAME]` generates a Rails 8 app by running `rails new` and layering independent steps on top: database, app type, test framework, frontend (Stimulus or React with esbuild, bun or webpack), RuboCop, background jobs/cache/cable (Solid or Redis + Sidekiq), pagination, staging environment, application services, secrets handling, authentication (Rails 8 built-in or Devise), VCR, JS linting, Docker and Kamal, GitHub Actions CI, and mailers.
- Non-interactive use: `--database/-d`, `--javascript/-j`, `--config FILE` (YAML answers) and `--yes`.
- `opinionated_rails list` and `opinionated_rails info STEP_ID`.
- Checks for required tools (yarn or bun for React) before generating, and refuses to overwrite an existing directory.
- Final `bundle install`, JavaScript install and RuboCop autocorrect so a generated app boots and passes its own `bin/rubocop`, Brakeman and bundler-audit.
- Complete Kamal config (`config/deploy.yml`, `.kamal/secrets`), staging that cannot send production email, ESLint 9 flat config, Redis fail-fast in production, and warnings when an expected Rails edit cannot be made.
- Requires Rails 8.1 or newer in the 8.x series.
- Authentication is skipped for API-only apps (Rails' generator and Devise both assume browser sessions).
