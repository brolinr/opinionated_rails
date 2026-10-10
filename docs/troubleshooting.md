---
title: Troubleshooting
nav_order: 9
---

# Troubleshooting
{: .no_toc }

Every error and warning the tool prints, what causes it, and what to do. Errors print one line and exit with status `1`; warnings are printed in yellow and the run continues.
{: .note }

<details markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

## Errors before anything is generated

These happen first, so nothing has been created yet. Fix the cause and run the command again.

### Rails is not installed

> `Rails is not installed. Install it with `gem install rails`.`
> `Rails is not installed or `rails --version` failed. Install it with `gem install rails`.`

The tool runs `rails new`, so it needs a working `rails` command on your `PATH`.

```bash
gem install rails
rails --version
```

### Rails version not supported

> `Rails 7.2.0 is not supported. opinionated_rails needs Rails 8.1 or newer in the 8.x series. Update with `gem update rails`.`

The steps edit text that Rails 8.1 generates (Solid defaults, Kamal, authentication), so other versions are rejected before any prompt rather than risk a half-working app. Run `gem update rails`. If you have several versions installed, check which one `rails --version` resolves to.

### Directory already exists

> `Directory my_app already exists`

The tool never generates into an existing directory. Choose another name, or remove the directory.

### Unknown option

> `Unknown option(s): databse. Valid keys: app_name, database, ...`

A key in your [config file](config-file.html) is misspelled or does not exist. Use one of the listed keys.

### Invalid value

> ``Invalid value "oracle" for `database`. Choose one of: sqlite, postgresql, mysql``

A flag or config value is not one of the key's choices. The message lists the valid ones. See the table in [Config file](config-file.html#keys).

> ``Invalid value "--force" for `auth_model`. Use a CamelCase constant such as User or Account.``

### Config file problems

> `Config file not found: PATH`
> `Config file must be a YAML mapping of answers: PATH`
> `Config file is not valid YAML (PATH): ...`

The path is wrong, the file is a list or a scalar instead of `key: value` pairs, or it has a YAML syntax error.

### No app name

> `No app name given (input ended)`

The name prompt received end of input, for example from a closed pipe. Pass the name as an argument (`opinionated_rails new my_app`) or set `app_name` in a config file.

### Invalid app name

> `Invalid app name "9bad": ...`
> `Invalid: ...`

The name must be a valid Ruby constant once camelized, must not start with a digit, and must not be reserved (`test`, `application`). A bad name on the command line makes the tool ask you instead.

### Missing tools for React

> `The React frontend needs tools that are not on your PATH:`
> `  - yarn: enable it with `corepack enable` or install it with `npm install -g yarn``

Rails' JavaScript install shells out to `yarn` (esbuild, webpack) or `bun`, and silently skips installing the bundler when it is missing, which leaves an app that cannot build. So the tool checks first. Install what it lists, or pass `--skip-bundle-install` to only scaffold files (you then install and build yourself).

### Invalid value rejected by a step

> ``Invalid value "9bad" for `app_name` (App name:)``

A preset answer was accepted by the file check but rejected by the step that asks the question. The run stops instead of asking forever. Correct the value.

## Errors during generation

### A step failed partway

> ``Step `faker` failed: ...``
> `The partially generated app is in /path/to/my_app. Fix the problem above, then delete that directory and run the command again (re-running over it is not supported).`

Something failed after `rails new` created the app. The message names the step, and the first line carries the underlying error. The half-built app is left in place so you can inspect it. Fix the cause, delete the directory, and run again. Because answers can come from a config file, re-running is quick.

The finishing steps appear the same way, under these names: `bundle install`, `JavaScript install`, `Tailwind build` and `RuboCop autocorrect`.

Common causes:

| Underlying message | Cause |
| --- | --- |
| `final bundle install failed` | A gem could not install, usually the `pg` or `mysql2` gem missing its client libraries (`libpq`, `libmysqlclient`), or no network |
| `yarn install failed`, `yarn run build failed`, `bun run build failed` | A JavaScript package or build error. Run the same command in the app to see the full output |
| `bin/rails tailwindcss:build failed` | Tailwind could not build. Run it in the app for details |
| `kamal init failed`, `rails generate ... failed`, `bundle install failed` | A generator failed. The output above the message has the reason |

## Warnings

### Ignored options

> `Ignored options (their prompt did not apply): bundler`

A key in your config never matched a question. For example, `bundler` only applies to React, and `factory` only to RSpec. Harmless; remove the key to silence it.

### Authentication skipped

> `Authentication is skipped for API-only apps: Rails' built-in generator and Devise both generate browser-session code that does not work without cookies and views.`

By design. See [Authentication](options.html#authentication).

### yarn or bun not found at the end

> `Warning: yarn not found; run `yarn install` and its build scripts in the app.`

You passed the up-front check but the tool is gone by the end (or the app has a `package.json` without React, for example from JavaScript linting). Run the install and build scripts yourself.

### RuboCop still reports offenses

> `Warning: bin/rubocop still reports offenses in the generated app; run it to review.`

The safe autocorrect fixed what it could. Run `bin/rubocop` to see the rest.

### Could not make an edit to Rails' files

> ``Warning: could not switch config/environments/production.rb to Redis (expected Rails text not found). Set it by hand: config.cache_store = :redis_cache_store ...``
> ``Warning: config/cable.yml has no Solid Cable or Redis production block; set `adapter: redis` by hand.``
> ``Warning: could not find `...` in config/environments/production.rb; add these lines yourself:``
> `Warning: config/environments/production.rb not found; mailer settings were not added.`
> ``Warning: could not find `entrypoints: ["app/javascript/application.js"]` in bun.config.js; set the entry point to app/javascript/application.jsx by hand.``

A step edits text that Rails generates (for bun, the entry point in `bun.config.js`, which must be `application.jsx` because that is the file the React step writes). If a Rails release rewords it, the step prints the exact setting to apply by hand instead of silently skipping. Apply what the message shows. If you see this for a Rails version the tool claims to support, please [open an issue](https://github.com/brolinr/opinionated_rails/issues) with the Rails version.

### Credentials may not work

> `Warning: config/master.key or config/credentials.yml.enc is missing — Rails credentials may not work as expected.`

You chose Rails credentials but the key or encrypted file is not in the app. Run `bin/rails credentials:edit` to create them.

### The `@` alias is editor-only

> `Warning: the @ import alias is configured for editor/TypeScript tooling only and won't resolve at build time until a bundler-specific config is added (current bundler: bun).`

`jsconfig.json` maps `@/` to `app/javascript` for your editor. esbuild and webpack resolve it at build time; bun needs its own configuration.

## Problems in a generated app

### `REDIS_URL is not set`

The app was started in production on the Redis + Sidekiq stack without `REDIS_URL`. Set it (the generated `deploy.yml` does). It is deliberately not defaulted to a local Redis in production. The Docker asset precompile is exempt.

### `The asset 'tailwind.css' was not found in the load path`

The CSS has not been built. The generator builds it once, but build output is git-ignored, so a fresh clone lacks it. Run `bin/rails db:test:prepare` (which triggers the build) or `bin/rails tailwindcss:build`; for React, `yarn run build && yarn run build:css`. The generated CI does this for you.

### `schema.rb doesn't exist yet`

A new app has migrations but no `db/schema.rb`. Run `bin/rails db:migrate`, then commit `db/schema.rb`.

### `invalid byte sequence in US-ASCII`

Not from this tool: it forces UTF-8 for its own files. If a Ruby tool in your pipeline reports it, set `LANG=en_US.UTF-8` (or `C.UTF-8`) in the environment.

## Still stuck

Run the failing command on its own inside the generated app to see its full output. Then open an issue at [github.com/brolinr/opinionated_rails/issues](https://github.com/brolinr/opinionated_rails/issues) with: the exact command (or your config file), `rails --version`, `ruby --version`, and the full error.
