# OpinionatedRails

`opinionated_rails` is an interactive CLI that generates a Rails app by composing independent, opinionated options instead of one fixed "house style". It runs `rails new`, then walks you through a series of self-contained steps (database, testing, frontend, CI, auth, background jobs, deployment and more). Each step has its own prompt, a sensible default, and its own generation logic.

## Requirements

- Ruby 3.2 or newer and Bundler
- Rails 8.1 or newer in the 8.x series installed (`gem install rails`). Other versions are rejected before anything is generated.
- Network access, unless you pass `--skip-bundle-install`
- For React: Node.js and `yarn` (esbuild, webpack) or `bun`. Checked before anything is generated, with instructions if missing.
- The client libraries for the database you pick (PostgreSQL or MySQL), so its gem can compile

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
| Frontend (full-stack only) | Stimulus + Hotwire, React (then esbuild, bun or webpack) |
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

#### Skipping the prompts

Every prompt can be answered up front, so a run can be scripted or repeated exactly. Unanswered prompts are asked as usual, or take their default with `--yes`.

```bash
# like `rails new -d postgresql -j esbuild`: React with esbuild, PostgreSQL, everything else default
opinionated_rails new my_app --database postgresql --javascript esbuild --yes

# every answer from a file
opinionated_rails new my_app --config answers.yml --yes
```

| Option | Meaning |
| --- | --- |
| `-d, --database` | `sqlite3`, `postgresql` or `mysql` |
| `-j, --javascript` | Use React with this bundler: `esbuild`, `bun` or `webpack` |
| `-c, --config FILE` | YAML file of answers (flags win over the file) |
| `-y, --yes` | Accept the default for anything not answered |

Config file keys (all optional): `app_name`, `database`, `app_type` (`full-stack`, `api-only`), `test_framework` (`minitest`, `rspec`), `frontend` (`stimulus`, `react`), `bundler` (`esbuild`, `bun`, `webpack`), `rubocop` (`omakase`, `custom`), `stack` (`solid`, `redis`), `pagination` (`pagy`, `geared_pagination`), `secrets` (`rails_credentials`, `dotenv`), `auth` (`none`, `rails8`, `devise`), `auth_model`, `factory` (`factorybot`, `fixtures`), and the yes/no switches `staging`, `services`, `vcr`, `js_lint`, `kamal`, `ci`, `mailer`.

```yaml
database: postgresql
test_framework: rspec
stack: redis
staging: true
auth: devise
auth_model: Account
```

Values are checked before anything is generated, so a typo exits immediately with the list of valid choices. Keys whose prompt does not apply (for example `bundler` for a Stimulus app) are reported and ignored. More ready-made examples live in `spec/fixtures/combos/`.

#### What the finished app looks like

- All gems are installed (`bundle install` runs once more after the last step) and the app's own RuboCop config is applied with safe autocorrect, so `bin/rubocop` is clean on the first run.
- The CI workflow runs tests, RuboCop, Brakeman and bundler-audit, and starts PostgreSQL, MySQL or Redis service containers to match your choices. It uses read-only token permissions.
- Choosing Redis + Sidekiq removes the Solid gems and their config, and points the cache store, Active Job and Action Cable at Redis (`REDIS_URL`).
- A staging environment copies `production.rb` and adds `staging:` entries to `database.yml`, `cable.yml`, `cache.yml` and `queue.yml`. It uses `*_staging` database names, not your production ones.

- With Kamal, `config/deploy.yml` and `.kamal/secrets` are complete for your stack: `RAILS_MASTER_KEY` and (for PostgreSQL/MySQL) `DATABASE_URL` as secrets, a persistent volume for SQLite data and uploads, and for Redis + Sidekiq a `job` role plus a Redis accessory. Only the `CHANGE_ME_*` values (server IP, registry, host) are left for you; `bin/kamal config` validates the file.
- Staging uses the `:test` mail delivery method, so it cannot send real email through your production Postmark account (the generated file explains how to give it its own Postmark server).
- React apps build their JavaScript and CSS at generation time, and ESLint 9 lints both `.js` and `.jsx`. React works with esbuild, bun and webpack (webpack gets Babel for JSX).
- Tailwind CSS is built once at the end for Stimulus apps, so the first `bin/rails test` passes. In CI, `db:test:prepare` rebuilds it.
- Production fails fast with `REDIS_URL is not set` on the Redis stack, except during the Docker asset precompile.
- If a Rails release rewords text the steps edit (cache store, queue adapter, mailer settings), the step prints a warning with the exact setting to apply by hand instead of silently skipping it.

Before deploying, review the generated placeholders: Postmark credentials, the `default_url_options` host, the `CHANGE_ME_*` values in Kamal's files, and (for staging) its hosts and credentials.

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

## How it is tested

Besides the unit specs, a slow suite generates a real app for each file in `spec/fixtures/combos/` (SQLite, PostgreSQL, MySQL, API-only, Rails 8 auth, Devise, React with esbuild/bun/webpack, Redis + Sidekiq, staging, Kamal, and more). Each app must boot in development, production and staging, pass its own RuboCop, Brakeman and bundler-audit, validate with `kamal config`, and pass the generated CI workflow's own test steps from a clean checkout. It runs nightly in GitHub Actions (`.github/workflows/ci.yml`). The same files work as `--config` examples.

`bundle exec rake pins:check` confirms every pinned gem and npm version still exists on its registry and lists newer ones.

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
