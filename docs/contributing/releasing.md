---
title: Releasing
parent: Contributing
nav_order: 4
description: "From a change to a published release: CI, docs deploys, versioning, the tag-based RubyGems release with trusted publishing, and how to recover."
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

## From a change to a release

Changes reach people in two different ways:

| What changed | How it reaches people | You need |
| --- | --- | --- |
| Docs (`docs/**`) | Redeployed to GitHub Pages automatically when it reaches `main` | Nothing else. No release |
| The gem (anything under `lib/`) | Published to RubyGems when you push a version tag | A version bump, a changelog entry and a tag |

### 1. Make and verify the change

1. Branch, make the change and add specs. A change to a step also needs a real-app combo (see the [checklist](writing-a-step.html#checklist-for-adding-or-changing-an-option)).
2. Run, locally:

   ```bash
   bundle exec rspec
   bundle exec rubocop
   bundle exec rake docs:check   # after a step change, run `rake docs:steps` first
   ```

3. Open a pull request. CI runs the fast suite on Ruby 3.2, 3.3 and 3.4, RuboCop, bundler-audit, `pins:check` and the docs build. The `generated-apps` job (12 real apps, including MySQL and bun) runs only on pushes to `main` and nightly, not on pull requests.
4. Merge to `main` when CI is green.

### 2. Decide whether to release

Docs-only changes are already live after step 1. A change to the gem does not reach users until you release it. Wait for the `generated-apps` job on `main` to finish green first: it is the proof that every supported combination still works.

### 3. Release

Pick the [version](#versioning), update `CHANGELOG.md`, push, wait for CI, then tag and push the tag. The exact commands are in [To release](#to-release). The workflow then verifies, waits for your approval, publishes to RubyGems and creates the GitHub release.

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

## Publishing

Releases are published by GitHub Actions (`.github/workflows/release.yml`) when you push a version tag. It uses RubyGems **trusted publishing**, so no API key is stored anywhere, and the gem's `rubygems_mfa_required` setting is satisfied by the trusted identity.

### One-time setup

1. **Create the trusted publisher on rubygems.org.** Sign in, open [Trusted Publishers](https://rubygems.org/profile/oidc/pending_trusted_publishers) and add a *pending* publisher (it works before the gem exists):

   | Field | Value |
   | --- | --- |
   | Gem name | `opinionated_rails` |
   | Repository owner | `brolinr` |
   | Repository name | `opinionated_rails` |
   | Workflow filename | `release.yml` |
   | Environment | `rubygems` |

   The first successful release turns it into a normal trusted publisher for the gem.

2. **Create the `rubygems` environment on GitHub.** In the repository: **Settings → Environments → New environment**, named `rubygems`. Add yourself as a required reviewer so every publish waits for your approval. This is optional but recommended: a publish cannot be undone.

### To release

1. Set the new version in `lib/opinionated_rails/version.rb`.
2. In `CHANGELOG.md`, change the heading to `## X.Y.Z (YYYY-MM-DD)`. The workflow refuses a heading that still says `unreleased`.
3. Commit and push to `main`, and wait for CI to pass.
4. Tag and push the tag:

   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

The workflow then:

1. **Verifies**: the tag equals `v` plus the gem's version, the changelog has a released entry, then the specs, RuboCop, `rake pins:check` and `rake docs:check` all pass.
2. **Waits for your approval**, if you set a required reviewer on the `rubygems` environment.
3. **Publishes** the gem to RubyGems, then creates a GitHub release whose notes are that version's changelog section.

If verification fails nothing is published. Fix the problem, delete the tag (`git push origin :refs/tags/vX.Y.Z` and `git tag -d vX.Y.Z`), and tag again.

A published version cannot be replaced. `gem yank` removes it, but the number can never be reused, so fix forward with a new patch version.
{: .warning }

### Publishing by hand

Only if the workflow is unavailable:

```bash
bundle exec rake build      # builds pkg/opinionated_rails-X.Y.Z.gem
gem push pkg/opinionated_rails-X.Y.Z.gem   # asks for your one-time MFA code
```

`packaging_spec.rb` has already built the gem and run its executable from an isolated gem home. If you add a new top-level directory the gem needs at runtime, add it to `spec.files` in `opinionated_rails.gemspec`; the spec checks all of `lib/opinionated_rails/templates/`.

## Things to know

- **Tags are permanent.** A pushed tag can never be reused or moved. If a release fails, fix forward with a new patch version.
- **A re-run uses the workflow from the tag's commit.** If the fix is in `.github/workflows/release.yml`, re-running the failed job will fail the same way; push the fix to `main` and cut a new tag.
- **Published versions are permanent.** `gem yank` removes one, but its number is never reusable.
- **The tag and `version.rb` must agree.** The first gate in the workflow refuses a tag such as `v0.1.2` when the gem says `0.1.1`.
- **The changelog heading must be dated.** `## X.Y.Z (YYYY-MM-DD)`. A heading that still says `unreleased` is refused.
- **Verification failing publishes nothing.** Fix it on `main` and tag again with a new version.
- **Approval is yours.** The `publish` job waits at the `rubygems` environment until you approve it in the Actions tab. If you did not set a required reviewer, it proceeds automatically.
- **No API key exists to leak.** Publishing uses RubyGems trusted publishing, so the only thing to maintain is the publisher entry on rubygems.org (owner `brolinr`, repository `opinionated_rails`, workflow `release.yml`, environment `rubygems`).

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

### Search and sharing metadata

`jekyll-seo-tag` and `jekyll-sitemap` produce the page titles, descriptions, canonical URLs, Open Graph and Twitter tags, JSON-LD and `sitemap.xml` from each page's front matter and `docs/_config.yml`. Give every new page a unique `description` (70 to 160 characters) and a unique `title`; `docs_spec.rb` fails otherwise.

The sharing image and icons are generated, then committed, so the build needs no Python:

```bash
pip install pillow
python3 docs/_tools/social_card.py   # writes social-card.png, favicon-32.png, apple-touch-icon.png
```

`robots.txt` points at the sitemap, but crawlers only read a `robots.txt` at the root of a domain, so on a GitHub Pages *project* site (`brolinr.github.io/opinionated_rails/`) it is advisory. Submit `sitemap.xml` in Google Search Console and Bing Webmaster Tools instead.

One-time setup for the repository owner: in GitHub, **Settings → Pages → Source: GitHub Actions**.
