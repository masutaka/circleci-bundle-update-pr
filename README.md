# Circleci::Rubocop::Pr [![Gem Version][gem-badge]][gem-link]

circleci-rubocop-pr is a script for continues rubocop. Use in CircleCI

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'circleci-rubocop-pr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install circleci-rubocop-pr

## Usage

    $ circleci-rubocop-pr 'Git username' 'Git email address'

By default, it works only on master branch, but you can also explicitly specify any branches rather than only master branch by adding them to the arguments.

    $ circleci-rubocop-pr 'Git username' 'Git email address' master develop topic

<!--
[gem-badge]: https://badge.fury.io/rb/circleci-rubocop-pr.svg
[gem-link]: http://badge.fury.io/rb/circleci-rubocop-pr
-->
