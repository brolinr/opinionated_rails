# OpinionatedRails

`opinionated_rails` is an interactive CLI that generates a Rails app by composing independent, opinionated options instead of one fixed "house style". It runs `rails new`, then walks you through a series of self-contained steps (database, testing, frontend, CI, auth, background jobs, deployment and more). Each step has its own prompt, a sensible default, and its own generation logic.

## Requirements

- Ruby 3.2 or newer and Bundler
- Rails 8 installed (`gem install rails`). Generated apps are built and tested against Rails 8.1.
- Network access, unless you pass `--skip-bundle-install`
- Git, Node.js (only for the React frontend and JS linting), and the client libraries for the database you pick (PostgreSQL or MySQL)

## Installation

```bash
gem install opinionated_rails
```

## Usage

### `opinionated_rails new [APP_NAME]`

Generates a new Rails app in `./APP_NAME`. If you give the name on the command line it is used directly; otherwise you are asked for it. The command refuses to run if the directory already exists.

```bash
opinionated_rails new my_app
```

You are prompted in this order. Press enter at any prompt to accept its default.

| Prompt | Choices (default first) |
| --- | --- |
| Database | SQLite, PostgreSQL, MySQL |
| App type | Full-stack, API-only |
| Test framework | Minitest, RSpec |
| Frontend (full-stack only) | Stimulus + Hotwire, React (then esbuild, bun, rollup or webpack) |
| RuboCop style | Omakase, Custom |
| Background jobs / cache / cable | Solid Trifecta, Redis + Sidekiq |
| Pagination | pagy, geared_pagination |
| Staging environment | no, yes |
| Application services (`app/services`) | no, yes |
| Secrets handling | Rails credentials, dotenv |
| Authentication | None, Rails 8 built-in, Devise |
| Factories (RSpec only) | FactoryBot, fixtures |
| VCR | no, yes |
| JS linting (ESLint) | yes, no |
| Kamal deployment | no, yes (a Dockerfile is always generated) |
| CI (GitHub Actions) | yes, no |
| Mailer (Letter Opener in development, Postmark in production) | yes, no |

Always generated: `AGENT.md` and `STYLE.md`, GitHub pull request and issue templates, Faker, and a Dockerfile (via `dockerfile-rails`).

#### What the finished app looks like

- All gems are installed (`bundle install` runs once more after the last step) and the app's own RuboCop config is applied with safe autocorrect, so `bin/rubocop` is clean on the first run.
- The CI workflow runs tests, RuboCop, Brakeman and bundler-audit, and starts PostgreSQL, MySQL or Redis service containers to match your choices. It uses read-only token permissions.
- Choosing Redis + Sidekiq removes the Solid gems and their config, and points the cache store, Active Job and Action Cable at Redis (`REDIS_URL`).
- A staging environment copies `production.rb` and adds `staging:` entries to `database.yml`, `cable.yml`, `cache.yml` and `queue.yml`. It uses `*_staging` database names, not your production ones.

Before deploying, review the generated placeholders: Postmark credentials, `default_url_options` host, Kamal's `config/deploy.yml` and `.kamal/secrets`, and (for staging) its hosts and credentials.

Pass `--skip-bundle-install` to skip `bundle install` and every generator that needs it. This is fast and works offline, but the result is a scaffold only. Run `bundle install` yourself afterwards.

```bash
opinionated_rails new my_app --skip-bundle-install
```

### `opinionated_rails list`

Lists every step, optionally filtered by tier:

```bash
opinionated_rails list
opinionated_rails list --tier core
opinionated_rails list --tier addon
```

### `opinionated_rails info STEP_ID`

Shows a step's tier, summary, description, dependencies, and prompts:

```bash
opinionated_rails info docker_kamal
```

### Not yet available

`opinionated_rails add STEP_ID` (adding a step to an existing app) is not implemented and exits with an error. It is planned together with a manifest that records what each app was generated with.

## Development

After checking out the repo, run `bin/setup` to install dependencies, then:

```bash
bundle exec rspec        # fast suite, runs `rails new --skip-bundle` in a temp dir
bundle exec rubocop
RUN_INTEGRATION_SPECS=1 bundle exec rspec   # also runs the slow specs (real bundle install, needs network)
```

Specs answer prompts by text with `PromptShell` (`spec/support/prompt_shell.rb`), so reordering steps does not break them. See `CONTRIBUTING.md` and `STYLE.md` before writing a new step.

To install the gem locally, run `bundle exec rake install`. To release, bump the version in `version.rb` and run `bundle exec rake release`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/brolinr/opinionated_rails.
