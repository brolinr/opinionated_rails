---
title: Home
layout: home
nav_order: 1
description: Generate a Rails 8 app from opinionated, independently tested options.
---

<div class="hero">
  <span class="eyebrow">Rails 8 generator</span>
  <h1>Start a Rails app with your choices already made.</h1>
  <p class="lede">Pick the database, tests, frontend, jobs, auth, CI and deployment. <code>opinionated_rails</code> builds the app and checks that it boots and passes its own lint and security scans.</p>
  <div class="actions">
    <a class="btn btn-primary" href="getting-started.html">Get started</a>
    <a class="btn" href="options.html">Browse the options</a>
    <a class="btn" href="https://github.com/brolinr/opinionated_rails">GitHub</a>
  </div>
  <div class="install"><span class="prompt">$</span><span>gem install opinionated_rails</span></div>
</div>

## What you get
{: .section-title }

<div class="cards">
  <div class="card">
    <span class="icon">&#9703;</span>
    <h3>Composable options</h3>
    <p>Database, tests, Stimulus or React, Solid or Redis, Rails 8 auth or Devise, and more. Each is independent.</p>
  </div>
  <div class="card">
    <span class="icon">&#8635;</span>
    <h3>Repeatable runs</h3>
    <p>Every prompt has a flag and a config file key. Values are validated before anything is generated.</p>
  </div>
  <div class="card">
    <span class="icon">&#10003;</span>
    <h3>Checked, not just generated</h3>
    <p>The app boots in development, production and staging, and passes RuboCop, Brakeman and bundler-audit.</p>
  </div>
  <div class="card">
    <span class="icon">&#8599;</span>
    <h3>Deployment included</h3>
    <p>A complete Kamal config for your stack and a GitHub Actions workflow with the right services.</p>
  </div>
  <div class="card">
    <span class="icon">&#9888;</span>
    <h3>Fails loudly</h3>
    <p>If a Rails release changes text a step edits, you get the exact line to add, not a half-configured app.</p>
  </div>
  <div class="card">
    <span class="icon">&#9638;</span>
    <h3>Tested as real apps</h3>
    <p>A matrix generates a real app for every supported combination and runs its own checks.</p>
  </div>
</div>

## How it works
{: .section-title }

<ol class="steps">
  <li><strong>Choose</strong><span>Answer the prompts, pass flags, or point it at a YAML file.</span></li>
  <li><strong>Generate</strong><span>It runs <code>rails new</code>, then each step adds its gems and files in dependency order.</span></li>
  <li><strong>Finish</strong><span>Final installs, JavaScript and CSS builds, and a safe RuboCop autocorrect.</span></li>
  <li><strong>Ship</strong><span>Review the few placeholders, then deploy with Kamal.</span></li>
</ol>

## Try it
{: .section-title }

<div class="terminal">
  <div class="bar"><i></i><i></i><i></i><b>opinionated_rails new shop</b></div>
<pre><span class="c"># interactive: every prompt shows its default (excerpt)</span>
<span class="p">$</span> opinionated_rails new shop
Choose a database:
  1. SQLite
  2. PostgreSQL
  3. MySQL
Database (default: SQLite): <span class="k">postgresql</span>
Choose an app type:
  1. Full-stack
  2. API-only
App type (default: Full-stack):
Choose a test framework:
  1. Minitest
  2. RSpec
Test framework (default: Minitest): <span class="k">rspec</span></pre>
</div>

Or skip every question:

```bash
opinionated_rails new shop --database postgresql --javascript esbuild --yes
opinionated_rails new shop --config answers.yml --yes
```

A mistake fails immediately, before anything is generated:

```text
Invalid value "oracle" for `database`. Choose one of: sqlite, postgresql, mysql
```

## What it supports
{: .section-title }

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

Each combination is exercised by a [real-app test matrix](contributing/testing.html): every file in `spec/fixtures/combos/` generates a real app that must pass the health checks.
{: .note }

Rollup is not offered, because Rails' rollup setup cannot build the JSX the React option writes.
{: .warning }

## Where to go next
{: .section-title }

- **New here:** [Getting started](getting-started.html)
- **Every flag:** [Command line](command-line.html)
- **Scripting and CI:** [Config file](config-file.html)
- **Something went wrong:** [Troubleshooting](troubleshooting.html)
- **Change the tool:** [Contributing](contributing/)
