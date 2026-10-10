---
title: Contributing
nav_order: 10
has_children: true
permalink: /contributing/
---

# Contributing
{: .no_toc }

Bug reports and pull requests are welcome at [github.com/brolinr/opinionated_rails](https://github.com/brolinr/opinionated_rails).

New to the code? Read in this order:

1. [Architecture](architecture.html): how a run flows and what the main classes do.
2. [Writing a step](writing-a-step.html): the contract every option follows, and the checklist for adding one.
3. [Testing](testing.html): the fast suite, and the real-app matrix that proves a combination works.
4. [Style](style.html) and [Releasing](releasing.html).

## Set up

```bash
git clone https://github.com/brolinr/opinionated_rails
cd opinionated_rails
bin/setup
bundle exec rspec
bundle exec rubocop
```

Rails 8.1+ must be installed (`gem install rails`), because the fast suite runs a real `rails new --skip-bundle`.

## The principle

A generator can write exactly the text you expect and still produce an app that cannot boot. Several real bugs in this project did (a pagination module that no longer exists, a half-removed Redis stack, a missing root route). So **the proof that a change works is a generated app that boots and passes its own checks**, not a string assertion. Unit specs are necessary; the [real-app matrix](testing.html#the-real-app-matrix) is what you rely on.
