# Changelog

## 0.1.1 (2026-10-10)

The first published release. Version 0.1.0 was tagged but never published: it was missing the MySQL and bun fixes below.

- `opinionated_rails new [APP_NAME]` generates a Rails 8 app by running `rails new` and layering independent steps on top: database, app type, test framework, frontend (Stimulus or React with esbuild, bun or webpack), RuboCop, background jobs/cache/cable (Solid or Redis + Sidekiq), pagination, staging environment, application services, secrets handling, authentication (Rails 8 built-in or Devise), VCR, JS linting, Docker and Kamal, GitHub Actions CI, and mailers.
- Non-interactive use: `--database/-d`, `--javascript/-j`, `--config FILE` (YAML answers) and `--yes`.
- `opinionated_rails list` and `opinionated_rails info STEP_ID`.
- Checks for required tools (yarn or bun for React) before generating, and refuses to overwrite an existing directory.
- Final `bundle install`, JavaScript install and RuboCop autocorrect so a generated app boots and passes its own `bin/rubocop`, Brakeman and bundler-audit.
- Complete Kamal config (`config/deploy.yml`, `.kamal/secrets`), staging that cannot send production email, ESLint 9 flat config, Redis fail-fast in production, and warnings when an expected Rails edit cannot be made.
- Requires Rails 8.1 or newer in the 8.x series.
- Authentication is skipped for API-only apps (Rails' generator and Devise both assume browser sessions).

### Fixed since the 0.1.0 tag

- `--database mysql` failed in `rails new`, because Rails 8.1 accepts `mysql` and the tool passed `mysql2`.
- React with bun failed to build: Rails' `bun.config.js` pointed at `application.js`, but the React step writes `application.jsx`. The entry point is now set to `application.jsx`, with a warning if Rails' file has changed.
- Added a RubyGems release workflow (trusted publishing, triggered by a version tag).

## 0.1.0 (2026-10-10, tagged but not published)

Superseded by 0.1.1.
