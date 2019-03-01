# Circleci::Bundle::Update::Pr

[![Build Status](https://img.shields.io/circleci/project/github/masutaka/circleci-bundle-update-pr/master.svg?logo=circieci&style=flat-square)][circleci]
[![License](https://img.shields.io/github/license/masutaka/circleci-bundle-update-pr.svg?style=flat-square)][license]
[![Gem](https://img.shields.io/gem/v/circleci-bundle-update-pr.svg?logo=ruby&style=flat-square)][gem-link]

[circleci]: https://circleci.com/gh/masutaka/circleci-bundle-update-pr
[license]: https://github.com/masutaka/circleci-bundle-update-pr/blob/master/LICENSE.txt
[gem-link]: http://badge.fury.io/rb/circleci-bundle-update-pr

`circleci-bundle-update-pr` is an automation script for continuous bundle update and for sending a pull request using [`Scheduling a Workflow of CircleCI`](https://circleci.com/docs/2.0/workflows/#scheduling-a-workflow).

By requesting a nightly build to CircleCI with an environment variable configured in `circle.yml` or `.circleci/config.yml` to execute this script, bundle update is invoked, then commit changes and send a pull request to GitHub repository if there some changes exist.

## Installation

```
$ gem install circleci-bundle-update-pr
```

## Prerequisites

The application on which you want to run continuous bundle update must be configured to be built on CircleCI.

## Usage

### Setting GitHub personal access token to CircleCI

GitHub personal access token is required for sending pull requests to your repository.

1. Go to [your account's settings page](https://github.com/settings/tokens) and generate a personal access token with "repo" scope
2. On CircleCI dashboard, go to your application's "Project Settings" -> "Environment Variables"
3. Add an environment variable `GITHUB_ACCESS_TOKEN` with your GitHub personal access token
    * If use GitHub Enterprise
        * `ENTERPRISE_OCTOKIT_ACCESS_TOKEN` with your GitHub Enterprise personal access token
        * `ENTERPRISE_OCTOKIT_API_ENDPOINT` with your GitHub Enterprise api endpoint (e.g. https://www.example.com/api/v3)

### Configure circle.yml

Configure your `circle.yml` or `.circleci/config.yml` to run `circleci-bundle-update-pr`, for example:

```yaml
version: 2
jobs:
  build:
    # snip
  continuous_bundle_update:
    docker:
      - image: ruby:2.4.2-alpine
    working_directory: /work
    steps:
      - run:
          name: Install System Dependencies
          command: |
            # See also https://circleci.com/docs/2.0/custom-images/#adding-required-and-custom-tools-or-files
            apk add --update --no-cache git openssh-client tar gzip ca-certificates \
              tzdata
            gem install -N bundler
      - run:
          name: Set timezone to Asia/Tokyo
          command: cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
      - checkout
      - restore_cache:
          name: Restore bundler cache
          keys:
            - gems-{{ .Environment.COMMON_CACHE_KEY }}-{{ checksum "Gemfile.lock" }}
            - gems-{{ .Environment.COMMON_CACHE_KEY }}-
      - run:
          name: Setup requirements for continuous bundle update
          command: gem install -N circleci-bundle-update-pr
      - deploy:
          name: Continuous bundle update
          command: circleci-bundle-update-pr <username> <email>

workflows:
  version: 2
  build:
    jobs:
      - build:
          # snip
  nightly:
    triggers:
      - schedule:
          cron: "00 10 * * 5"
          filters:
            branches:
              only: master
    jobs:
      - continuous_bundle_update
```

NOTE: Please make sure you replace `<username>` and `<email>` with yours.

`circleci-bundle-update-pr` regularly updates myself. See also [.circleci/config.yml](.circleci/config.yml).

## CLI command references

General usage:

```
$ circleci-bundle-update-pr <git username> <git email address>
```

By default, it works only on master branch, but you can also explicitly specify any branches rather than only master branch by adding them to the arguments.

```
$ circleci-bundle-update-pr <git username> <git email address> master develop topic
```

You can also add the following options:

```
$ circleci-bundle-update-pr -h
Usage: circleci-bundle-update-pr [options]
    -a, --assignees alice,bob,carol  Assign the PR to them
    -r, --reviewers alice,bob,carol  Request PR review to them
    -l, --labels "In Review, Update" Add labels to the PR
    -d, --duplicate                  Make PR even if it has already existed
```

## Tips

### Customize PR description

If `.circleci/BUNDLE_UPDATE_NOTE.md` exists, the content will be appended to PR description.

e.g. `.circleci/BUNDLE_UPDATE_NOTE.md` is the below.

```
## Notice

* example1
* example2
```

PR description will be created as the below.

```
**Updated RubyGems:**

* [ ] [octokit](https://github.com/octokit/octokit.rb): [`4.9.0...4.10.0`](https://github.com/octokit/octokit.rb/compare/v4.9.0...v4.10.0)
* [ ] [public_suffix](https://github.com/weppos/publicsuffix-ruby): [`3.0.2...3.0.3`](https://github.com/weppos/publicsuffix-ruby/compare/v3.0.2...v3.0.3)

Powered by [circleci-bundle-update-pr](https://rubygems.org/gems/circleci-bundle-update-pr)

---

## Notice

* example1
* example2
```

`.circleci/BUNDLE_UPDATE_NOTE.md` or `CIRCLECI_BUNDLE_UPDATE_NOTE.md`, either one is OK. It gives priority `.circleci/BUNDLE_UPDATE_NOTE.md` over `CIRCLECI_BUNDLE_UPDATE_NOTE.md`.

## Contributing

1. Fork it ( https://github.com/masutaka/circleci-bundle-update-pr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
