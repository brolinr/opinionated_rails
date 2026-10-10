---
title: Home
layout: home
nav_order: 1
---

# opinionated_rails
{: .no_toc }

Generate a Rails 8 app by choosing from independent, opinionated options. The tool runs `rails new`, then layers on exactly the pieces you picked (database, tests, frontend, background jobs, authentication, CI, deployment and more) and checks the result boots and passes its own linting and security scans.
{: .fs-6 .fw-300 }

[Get started](getting-started.html){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/brolinr/opinionated_rails){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Quick start

```bash
gem install opinionated_rails

# answer the prompts (press enter to accept a default)
opinionated_rails new my_app

# or script it: PostgreSQL, React with esbuild, everything else default
opinionated_rails new my_app --database postgresql --javascript esbuild --yes
```

You need Rails 8.1 or newer installed (`gem install rails`). For React you also need `yarn` (esbuild, webpack) or `bun`; the tool checks this before it generates anything. See [Getting started](getting-started.html) for the full requirements.

## What you get

- **A working app, not a scaffold.** The generated app boots in development, production and staging, and `bin/rubocop`, `bin/brakeman` and `bin/bundler-audit` pass on the first run. See [The generated app](generated-app.html).
- **Repeatable runs.** Every prompt has a [config file key](config-file.html) and a flag, and values are validated before anything is generated.
- **Deployment included.** Optional [Kamal](deploying.html) files complete for your stack, plus a GitHub Actions workflow that builds, scans and tests.
- **Safe failure.** If a Rails release changes text a step edits, you get a warning with the exact line to add, not a silently half-configured app.

## What it supports

| Area | Supported |
| --- | --- |
| Rails | 8.1 or newer in the 8.x series (other versions are rejected up front) |
| Ruby | 3.2, 3.3, 3.4 |
| Database | SQLite, PostgreSQL, MySQL |
| App type | Full-stack, API-only |
| Tests | Minitest, RSpec (with FactoryBot or fixtures) |
| Frontend | Stimulus + Hotwire, or React with esbuild, bun or webpack |
| Jobs, cache, cable | Solid Trifecta, or Redis + Sidekiq |
| Authentication | None, Rails 8 built-in, Devise (full-stack apps only) |

Every combination in the table is exercised by a [real-app test matrix](contributing/testing.html): each file in `spec/fixtures/combos/` generates a real app that must pass the health checks. Rollup is not offered, because Rails' rollup setup cannot build the JSX the React option writes.

## Where to go next

- New here: [Getting started](getting-started.html)
- Every flag: [Command line](command-line.html)
- Every option and what it generates: [Options](options.html)
- Scripting and CI: [Config file](config-file.html)
- Something went wrong: [Troubleshooting](troubleshooting.html)
- Want to change the tool: [Contributing](contributing/)
