---
title: Deploying
nav_order: 7
---

# Deploying with Kamal
{: .no_toc }

Choose Kamal (`kamal: true`) and the tool writes `config/deploy.yml` and `.kamal/secrets` for your stack. The generated `Dockerfile` comes from `dockerfile-rails`. Only the values it cannot know are left as `CHANGE_ME_*`.

1. TOC
{:toc}

## What you fill in

| Placeholder | Meaning |
| --- | --- |
| `CHANGE_ME_registry_username` | Your container registry user (appears twice: `image` and `registry`) |
| `CHANGE_ME_server_ip` | The server to deploy to (also for the `job` role and Redis accessory with Sidekiq) |
| `CHANGE_ME.example.com` | The host Kamal's proxy should serve, with automatic SSL |

`bin/kamal config` parses and validates the file without touching a server. The placeholders are valid strings, so it passes before you edit them.

## What is already done for you

**Secrets.** `RAILS_MASTER_KEY` is passed to the container, read from `config/master.key`. For PostgreSQL and MySQL, `DATABASE_URL` is a secret read from your environment. `KAMAL_REGISTRY_PASSWORD` is read from your environment. `.kamal/secrets` is safe to commit: it contains no values, only references.

```bash
export KAMAL_REGISTRY_PASSWORD=...          # a registry access token
export DATABASE_URL=postgres://...          # PostgreSQL or MySQL only
```

**Persistent data.** Without a volume, every deploy starts from an empty database.

| Database | Volumes |
| --- | --- |
| SQLite | `<app>_data:/data` (the database) and `<app>_storage:/rails/storage` (uploads) |
| PostgreSQL, MySQL | `<app>_storage:/rails/storage` |

**Background jobs.**

| Stack | Setup |
| --- | --- |
| Solid | `SOLID_QUEUE_IN_PUMA: true`, so jobs run inside the web process on a single server |
| Redis + Sidekiq | A `job` role running `bundle exec sidekiq`, a Redis accessory (`redis:7` with persistence), and `REDIS_URL` pointing at it |

**Assets.** `asset_path: /rails/public/assets` keeps old fingerprinted assets available to in-flight requests during a deploy.

**Aliases.** `bin/kamal console`, `shell`, `logs` and `dbc`.

## First deploy

```bash
bin/kamal setup      # first time: installs Docker on the server, boots accessories, deploys
bin/kamal deploy     # later deploys
```

See the [Kamal documentation](https://kamal-deploy.org) for registries, multiple servers, and destinations.

## Staging

Choosing a staging environment adds a Rails `staging` environment, but not a separate Kamal destination. To deploy staging, create `config/deploy.staging.yml` and `.kamal/secrets.staging` (see Kamal's *destinations*), and set `RAILS_ENV` for it.

Staging uses the `:test` mail delivery method, so it cannot send email through your production Postmark account. To test real delivery, create a separate Postmark server for staging and follow the comment in `config/environments/staging.rb`.

## Redis in production

With Redis + Sidekiq the app refuses to boot in production without `REDIS_URL`; the generated `deploy.yml` sets it for you. The Docker build runs `assets:precompile` with `SECRET_KEY_BASE_DUMMY` set, which is exempt, so image builds do not need Redis.
