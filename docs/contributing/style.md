---
title: Style
parent: Contributing
nav_order: 5
description: "Where opinionated_rails documents its code conventions, and how its style is enforced with RuboCop."
---

# Style
{: .no_toc }

The conventions the codebase has converged on live in [`STYLE.md`](https://github.com/brolinr/opinionated_rails/blob/main/STYLE.md) in the repository root. It is the single source for step shape, idempotency, version pinning, the meaning of `needs`, soft reads, static templates, and how to write specs, so it is not duplicated here.

Code style is enforced by RuboCop (`rubocop-rails-omakase`): `bundle exec rubocop`. Match the surrounding code, and copy the shape of an existing step in the same tier before inventing a new one.
