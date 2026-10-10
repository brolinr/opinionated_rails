---
title: Command line
nav_order: 3
---

# Command line
{: .no_toc }

1. TOC
{:toc}

## `opinionated_rails new [APP_NAME]`

Generates a new app in `./APP_NAME`.

```bash
opinionated_rails new my_app [options]
```

| Option | Meaning |
| --- | --- |
| `APP_NAME` | The app name. If omitted you are asked (or it comes from `app_name` in a config file). Hyphens become underscores. It must be a valid Ruby constant once camelized and must not start with a digit. An invalid name given here is reported and you are asked instead |
| `-d`, `--database` | `sqlite3`, `postgresql` or `mysql`. Skips the database prompt. Rails-style names are accepted (`sqlite3`, `postgres`, `mysql2`) |
| `-j`, `--javascript` | Choose React with this bundler: `esbuild`, `bun` or `webpack`. Skips the frontend and bundler prompts |
| `-c`, `--config FILE` | YAML file of answers. See [Config file](config-file.html) |
| `-y`, `--yes` | Take the default for every question you have not answered |
| `--skip-bundle-install` | Skip `bundle install`, `yarn`/`bun` and every generator that needs them. Fast and works offline, but the result is a scaffold you must install yourself |

Precedence, highest first: the `APP_NAME` argument, `--database` / `--javascript`, the config file, then the interactive prompt (or the default with `--yes`).

Examples:

```bash
opinionated_rails new shop                                  # interactive
opinionated_rails new shop -y                               # all defaults
opinionated_rails new shop -d postgresql -j webpack -y
opinionated_rails new shop --config ci.yml --database mysql # flag beats the file
```

Values are checked before anything is generated. A typo exits immediately with the valid choices:

```text
Invalid value "oracle" for `database`. Choose one of: sqlite, postgresql, mysql
```

Config keys that do not apply (for example `bundler` for a Stimulus app) are ignored with a notice:

```text
Ignored options (their prompt did not apply): bundler
```

**Exit status.** `0` on success. Any error prints a one-line message (no backtrace) and exits `1`.

## `opinionated_rails list`

Lists every step.

```bash
opinionated_rails list
opinionated_rails list --tier core
opinionated_rails list --tier addon
```

## `opinionated_rails info STEP_ID`

Shows a step's tier, summary, description, dependencies and prompt.

```bash
opinionated_rails info docker_kamal
```

The full table is in the [step reference](steps.html).

## Not available

`opinionated_rails add STEP_ID` (adding a step to an app you already generated) and `status` are not implemented. `add` exits with an error. They are planned together with a manifest that records how each app was generated.
