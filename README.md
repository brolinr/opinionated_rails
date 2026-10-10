# opinionated_rails

Generate a Rails 8 app by choosing from independent, opinionated options. The tool runs `rails new`, then layers on exactly the pieces you picked (database, tests, frontend, background jobs, authentication, CI, deployment and more) and checks that the result boots and passes its own RuboCop, Brakeman and bundler-audit.

**Documentation: <https://brolinr.github.io/opinionated_rails/>**

## Quick start

```bash
gem install opinionated_rails        # needs Rails 8.1+ (gem install rails)

opinionated_rails new my_app         # answer the prompts; enter accepts a default

# or script it
opinionated_rails new my_app --database postgresql --javascript esbuild --yes
opinionated_rails new my_app --config answers.yml --yes
```

For React you also need `yarn` (esbuild, webpack) or `bun`. The tool checks before generating anything.

## What it can do

| Area | Options |
| --- | --- |
| Database | SQLite, PostgreSQL, MySQL |
| App type | Full-stack, API-only |
| Tests | Minitest, RSpec (FactoryBot or fixtures), VCR |
| Frontend | Stimulus + Hotwire, or React with esbuild, bun or webpack; Tailwind CSS; ESLint 9 |
| Jobs, cache, cable | Solid Trifecta, or Redis + Sidekiq |
| Authentication | Rails 8 built-in or Devise (full-stack apps) |
| Also | Pagination (pagy or geared_pagination), staging environment, application services, dotenv or Rails credentials, mailers, GitHub Actions CI, Docker and Kamal deployment |

Every choice has a flag or a [config file](https://brolinr.github.io/opinionated_rails/config-file.html) key, and values are validated before anything is generated.

## Documentation

- [Getting started](https://brolinr.github.io/opinionated_rails/getting-started.html)
- [Command line](https://brolinr.github.io/opinionated_rails/command-line.html) and [config file](https://brolinr.github.io/opinionated_rails/config-file.html)
- [Every option](https://brolinr.github.io/opinionated_rails/options.html) and [the generated app](https://brolinr.github.io/opinionated_rails/generated-app.html)
- [Deploying with Kamal](https://brolinr.github.io/opinionated_rails/deploying.html)
- [Troubleshooting](https://brolinr.github.io/opinionated_rails/troubleshooting.html)
- [Contributing](https://brolinr.github.io/opinionated_rails/contributing/): architecture, writing a step, testing, releasing

The sources are in [`docs/`](docs/). `opinionated_rails list` and `opinionated_rails info STEP_ID` show the steps in your terminal.

## Development

```bash
bin/setup
bundle exec rspec                          # fast suite
bundle exec rubocop
RUN_INTEGRATION_SPECS=1 bundle exec rspec  # also generates real apps for every combo (slow, needs network)
```

See [CONTRIBUTING.md](CONTRIBUTING.md), [STYLE.md](STYLE.md) and the [contributing guide](docs/contributing/).

## License

Released under the [MIT License](LICENSE.txt).
