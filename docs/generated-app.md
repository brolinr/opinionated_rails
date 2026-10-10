---
title: The generated app
nav_order: 6
description: "What a generated Rails app contains, the checks it passes on day one, its CI workflow, and what to review before you ship it."
---

# The generated app
{: .no_toc }

What you have when the tool finishes, and what has been checked for you.

<details markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

## Checked before you touch it

For the combinations in the [test matrix](contributing/testing.html), a freshly generated app has been shown to:

- resolve and install its bundle (and yarn or bun packages for React),
- boot and eager-load in **development**, **production** and **staging** (when selected),
- pass `bin/rubocop`, `bin/brakeman` and `bin/bundler-audit`,
- validate with `bin/kamal config` (when Kamal is selected),
- pass its own tests, using the steps of its generated CI workflow from a clean checkout,
- answer `/up` with 200, and `/` without a server error.

## Finishing steps

After the last step the tool runs, in this order:

1. `bundle install`: steps add gems after the last mid-run install.
2. `yarn install` (or `bun install`), then the `build` and `build:css` scripts, if the app has a `package.json`. Without built assets the first page load would fail with a missing-asset error.
3. `bin/rails tailwindcss:build` for apps using `tailwindcss-rails`, so the first `bin/rails test` passes.
4. `bin/rubocop -a`: safe autocorrect for code from generators the tool does not control, such as Devise.

Any failure here stops the run and names the step. See [Troubleshooting](troubleshooting.html#a-step-failed-partway).

## CI workflow

`.github/workflows/ci.yml` runs on pull requests and pushes to `main`:

| Job | What it does |
| --- | --- |
| `security` | `bin/brakeman` and `bin/bundler-audit`. (`rails new --skip-ci` drops Rails' own scan job, so these are kept here.) |
| `test` | Starts a PostgreSQL, MySQL and/or Redis service if you chose them, builds JavaScript and CSS for React apps, runs `bin/rails db:create db:migrate db:test:prepare`, then your tests |
| `rubocop` | `bin/rubocop -f github` |
| `js_lint` | ESLint, when JavaScript linting is on |

Workflow-wide: read-only `GITHUB_TOKEN` permissions, a concurrency group that cancels superseded runs, and a 15-minute timeout per job. The install step uses yarn or bun to match the app, never npm.

`db:create db:migrate` comes first because a new app has migrations but no `db/schema.rb` yet; commit the schema once you have one.

## Notable files

| File | Present when |
| --- | --- |
| `Dockerfile`, `.dockerignore` | always |
| `config/deploy.yml`, `.kamal/secrets` | Kamal |
| `config/environments/staging.rb` | staging |
| `config/initializers/sidekiq.rb` | Redis + Sidekiq |
| `config/initializers/pagy.rb` | pagy |
| `app/services/` | application services |
| `app/javascript/application.jsx`, `router.jsx` | React |
| `eslint.config.js` | JavaScript linting |
| `babel.config.json`, `webpack.config.js` | React with webpack |
| `.env.example` | dotenv |
| `spec/` or `test/support/vcr.rb` | RSpec / VCR |
| `AGENT.md`, `STYLE.md`, `.github/` templates | always |

## Things to review before you ship

The tool cannot know these, so check them:
{: .important }

- **Mail:** the `from` address in `ApplicationMailer`, `default_url_options` hosts, and your Postmark token.
- **Kamal:** every `CHANGE_ME_*` value. See [Deploying](deploying.html).
- **Staging:** hosts and credentials.
- **VCR:** extend `filter_sensitive_data` before recording cassettes.
- **Sidekiq Web:** left unmounted; add authentication before enabling it.
- **Schema:** commit `db/schema.rb` after your first migration.
