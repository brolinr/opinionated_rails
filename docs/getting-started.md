---
title: Getting started
nav_order: 2
---

# Getting started
{: .no_toc }

1. TOC
{:toc}

## Requirements

| You need | Why |
| --- | --- |
| Ruby 3.2 or newer | The gem's minimum |
| Rails 8.1 or newer (8.x) | `rails new` is what generates the base app. The tool reads `rails --version` and refuses anything else before asking a single question |
| Network access | `rails new` and the generators install gems (skip with `--skip-bundle-install`) |
| `yarn` or `bun` (React only) | Rails' JavaScript install and the final build use them. esbuild and webpack use yarn; bun uses bun |
| Node.js (React, or JS linting) | Runs the bundler and ESLint |
| PostgreSQL or MySQL client libraries | So the `pg` or `mysql2` gem can compile, if you pick those |

Missing tools for your choices are reported before anything is generated, with how to install them. See [Troubleshooting](troubleshooting.html).

## Install

```bash
gem install opinionated_rails
```

## Generate your first app

```bash
opinionated_rails new my_app
```

The tool asks for each option in turn. Every prompt shows its default; press enter to accept it. The first questions (name, database, app type, test framework, frontend) are asked before `rails new` runs, and the rest follow. See [Options](options.html) for what each one does.

To skip the questions:

```bash
opinionated_rails new my_app --yes                       # all defaults
opinionated_rails new my_app -d postgresql -j esbuild -y # PostgreSQL + React/esbuild
opinionated_rails new my_app --config answers.yml -y     # answers from a file
```

See [Command line](command-line.html) and [Config file](config-file.html).

## What happens, in order

1. **Checks.** The installed Rails version is verified, and your answers (from flags or a config file) are validated.
2. **Questions.** Core options are asked or taken from your answers. The app directory must not already exist.
3. **Tool check.** If you chose React, `yarn` or `bun` must be on your `PATH`.
4. **`rails new`** runs with the flags that follow from your choices. Rails' own Docker, Kamal and CI files are skipped, because the matching steps write better ones.
5. **Steps** run in dependency order (see the [step reference](steps.html)). Each adds its gems and files and asks its own question if it has one.
6. **Finishing.** One more `bundle install` (steps add gems after the last one), `yarn`/`bun` install and the JavaScript and CSS builds for React, the Tailwind build for Stimulus apps, and a safe RuboCop autocorrect so `bin/rubocop` is clean.

If a step fails after `rails new`, the half-built app is left in place and the message names the step. See [Troubleshooting](troubleshooting.html#a-step-failed-partway).

## Next steps

```bash
cd my_app
bin/rails db:create db:migrate
bin/dev            # or bin/rails server
bin/rails test     # or bundle exec rspec
```

Then read [The generated app](generated-app.html), and [Deploying](deploying.html) if you chose Kamal.
