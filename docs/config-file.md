---
title: Config file
nav_order: 4
---

# Config file
{: .no_toc }

A YAML file of answers makes a run repeatable: the same file produces the same app, in CI or on another machine.

<details markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

## Using it

```bash
opinionated_rails new my_app --config answers.yml --yes
```

Every key is optional. With `--yes`, anything not listed takes its default; without it, you are asked for the rest. Flags and the `APP_NAME` argument override the file. See [Command line](command-line.html).

```yaml
# answers.yml: PostgreSQL + Redis/Sidekiq, RSpec, Devise, staging, Kamal
database: postgresql
test_framework: rspec
stack: redis
staging: true
services: true
secrets: dotenv
auth: devise
vcr: true
kamal: true
```

## Keys

Values are case-insensitive. The yes/no keys accept `true`/`false` or `yes`/`no`.

| Key | Values | Default | Option |
| --- | --- | --- | --- |
| `app_name` | free text | asked | [App name](options.html#app-name) |
| `database` | `sqlite`, `postgresql`, `mysql` (also `sqlite3`, `postgres`, `pg`, `mysql2`) | `sqlite` | [Database](options.html#database) |
| `app_type` | `full-stack`, `api-only` | `full-stack` | [App type](options.html#app-type) |
| `test_framework` | `minitest`, `rspec` | `minitest` | [Test framework](options.html#test-framework) |
| `frontend` | `stimulus`, `react` | `stimulus` | [Frontend](options.html#frontend) |
| `bundler` | `esbuild`, `bun`, `webpack` | `esbuild` | [Frontend](options.html#frontend) (React only) |
| `rubocop` | `omakase`, `custom` | `omakase` | [RuboCop](options.html#rubocop) |
| `stack` | `solid`, `redis` | `solid` | [Jobs, cache and cable](options.html#jobs-cache-and-cable) |
| `pagination` | `pagy`, `geared_pagination` | `pagy` | [Pagination](options.html#pagination) |
| `staging` | yes/no | no | [Staging environment](options.html#staging-environment) |
| `services` | yes/no | no | [Application services](options.html#application-services) |
| `secrets` | `rails_credentials`, `dotenv` | `rails_credentials` | [Secrets](options.html#secrets) |
| `auth` | `none`, `rails8`, `devise` | `none` | [Authentication](options.html#authentication) |
| `auth_model` | a CamelCase constant such as `User` or `Account` | `User` | [Authentication](options.html#authentication) (Devise) |
| `factory` | `factorybot`, `fixtures` | `factorybot` | [Factories](options.html#factories) (RSpec only) |
| `vcr` | yes/no | no | [VCR](options.html#vcr) |
| `js_lint` | yes/no | yes | [JavaScript linting](options.html#javascript-linting) |
| `kamal` | yes/no | no | [Docker and Kamal](options.html#docker-and-kamal) |
| `ci` | yes/no | yes | [CI](options.html#ci) |
| `mailer` | yes/no | yes | [Mailer](options.html#mailer) |

## Validation

The file is checked before anything is generated, so mistakes cost you nothing:

| Problem | Result |
| --- | --- |
| A key that does not exist | `Unknown option(s): databse. Valid keys: ...` |
| A value outside the key's choices | ``Invalid value "oracle" for `database`. Choose one of: sqlite, postgresql, mysql`` |
| `auth_model` that is not a CamelCase constant | ``Invalid value "--force" for `auth_model`. Use a CamelCase constant such as User or Account.`` |
| The file does not exist | `Config file not found: PATH` |
| The file is not a YAML mapping | `Config file must be a YAML mapping of answers: PATH` |
| The file is not valid YAML | `Config file is not valid YAML (PATH): ...` |

A key whose question never applies (for example `bundler` when the frontend is Stimulus, or `factory` with Minitest) is ignored, and the tool says so at the end.

## Examples

These are the files the test matrix generates real apps from. Each is in `spec/fixtures/combos/` in the repository.

**Everything default** (`default.yml`):

```yaml
{}
```

**API-only on PostgreSQL** (`api_pg.yml`). Authentication is skipped for API-only apps (see [Authentication](options.html#authentication)):

```yaml
app_type: api-only
database: postgresql
staging: true
auth: rails8
```

**React with webpack** (`react_webpack.yml`):

```yaml
frontend: react
bundler: webpack
```

**Everything switched off** (`custom_everything_off.yml`):

```yaml
rubocop: custom
test_framework: rspec
factory: fixtures
pagination: geared_pagination
secrets: dotenv
vcr: true
js_lint: false
ci: false
mailer: false
```
