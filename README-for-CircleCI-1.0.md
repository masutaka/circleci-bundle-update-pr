# Circleci::Bundle::Update::Pr

[![Build Status](https://img.shields.io/circleci/project/masutaka/circleci-bundle-update-pr/master.svg?style=flat-square)][circleci]
[![License](https://img.shields.io/github/license/masutaka/circleci-bundle-update-pr.svg?style=flat-square)][license]
[![Gem](https://img.shields.io/gem/v/circleci-bundle-update-pr.svg?style=flat-square)][gem-link]

[circleci]: https://circleci.com/gh/masutaka/circleci-bundle-update-pr
[license]: https://github.com/masutaka/circleci-bundle-update-pr/blob/master/LICENSE.txt
[gem-link]: http://badge.fury.io/rb/circleci-bundle-update-pr

circleci-bundle-update-pr is an automation script for continuous bundle update and for sending a pull request via CircleCI [Nightly builds](https://circleci.com/docs/nightly-builds/).

By requesting a nightly build to CircleCI with an environment variable configured in `circle.yml` to execute this script, bundle update is invoked, then commit changes and send a pull request to GitHub repository if there some changes exist.

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

### Getting CircleCI API token

CircleCI API token is required to trigger nightly builds.

1. Go to your application's "Project Settings" -> "API Permissions"
2. Select "Create Token" and create a new token with "All" scope and any label you like

### Configure circle.yml

Configure your `circle.yml` to run `circleci-bundle-update-pr` if `BUNDLE_UPDATE` environment variable is present, for example:

```yaml
deployment:
  production:
    branch: master
    commands:
      - |
        if [ "${BUNDLE_UPDATE}" ] ; then
          gem update bundler -N
          gem install circleci-bundle-update-pr -N
          circleci-bundle-update-pr <username> <email>
        fi
```

NOTE: Please make sure you replace `<username>` and `<email>` with yours.

### Trigger nightly build API via curl

The easiest way to start a nightly build is using curl. The below is a simple script to trigger a build.

```bash
_project=<username>/<reponame>
_branch=master
_circle_token=<ciecleci api token>

trigger_build_url=https://circleci.com/api/v1/project/${_project}/tree/${_branch}?circle-token=${_circle_token}

post_data='{ "build_parameters": { "BUNDLE_UPDATE": "true" } }'

curl \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data "${post_data}" \
  --request POST ${trigger_build_url}
```

NOTE: Please do not forget to replace `<username>/<reponame>/<circleci api token>` with yours.


### Trigger nightly build via ci-build-trigger (recommended)

While you can trigger nightly builds by using whatever you want for sending requests to API, the most recommended way is to use "ci-build-trigger". Please see https://github.com/masutaka/ci-build-trigger for details.

## CLI command references

General usage:

```
$ circleci-bundle-update-pr <git username> <git email address>
```

By default, it works only on master branch, but you can also explicitly specify any branches rather than only master branch by adding them to the arguments.

```
$ circleci-bundle-update-pr <git username> <git email address> master develop topic
```

## Contributing

1. Fork it ( https://github.com/masutaka/circleci-bundle-update-pr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[gem-badge]: https://badge.fury.io/rb/circleci-bundle-update-pr.svg
[gem-link]: http://badge.fury.io/rb/circleci-bundle-update-pr
