---
title: Releasing
parent: Contributing
nav_order: 4
---

# Releasing
{: .no_toc }

<details markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

## Before a release

```bash
bundle exec rspec
bundle exec rubocop
bundle exec rake pins:check
RUN_INTEGRATION_SPECS=1 bundle exec rspec spec/opinionated_rails/integration/generated_apps_slow_spec.rb
```

Also confirm the `generated-apps` job is green in GitHub Actions on `main`: it covers MySQL, bun and the Ruby versions your machine may not have.

`rake pins:check` fails only if a pinned version no longer exists. It also lists newer versions. Bumping one is a normal change: update the constant (or the npm assignment), run the combos that use it, and note it in the changelog.

## Versioning

Semantic versioning. In `lib/opinionated_rails/version.rb`:

- **Patch**: bug fixes in what is generated.
- **Minor**: new options or flags, backwards-compatible config keys.
- **Major**: removing an option or key, changing a default, or dropping a supported Rails or Ruby version.

Update `CHANGELOG.md` with the user-visible changes under the new version.

## Build and publish

```bash
bundle exec rake build      # builds pkg/opinionated_rails-X.Y.Z.gem
gem push pkg/opinionated_rails-X.Y.Z.gem
```

`rake release` does the build, tags `vX.Y.Z`, pushes the commits and tag, and pushes the gem. The gemspec sets `rubygems_mfa_required`, so publishing asks for your one-time code.

`packaging_spec.rb` has already built the gem and run its executable from an isolated gem home. If you add a new top-level directory the gem needs at runtime, add it to `spec.files` in `opinionated_rails.gemspec`; the spec checks all of `lib/opinionated_rails/templates/`.

## Documentation

Pages in `docs/` publish to GitHub Pages from `main` via `.github/workflows/docs.yml`. The site is Jekyll with the `just-the-docs` theme.

```bash
cd docs
bundle install
bundle exec jekyll serve      # http://127.0.0.1:4000/opinionated_rails/
```

`docs/steps.md` is generated from the step classes. After changing a step's summary, description, prompt or dependencies:

```bash
bundle exec rake docs:steps
```

`bundle exec rake docs:check` (run in CI) fails if it is stale. `docs_spec.rb` also fails if the config keys, step list, error messages or links in the docs no longer match the code.

One-time setup for the repository owner: in GitHub, **Settings → Pages → Source: GitHub Actions**.
