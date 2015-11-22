# Circleci::Bundle::Update::Pr [![Gem Version][gem-badge]][gem-link]

circleci-bundle-update-pr is a script for continues bundle update. Use in CircleCI

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'circleci-bundle-update-pr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install circleci-bundle-update-pr

## Usage

    $ circleci-bundle-update-pr 'Git username' 'Git email address'

By default, it works only on master branch, but you can also explicitly specify any branches rather than only master branch by adding them to the arguments.

    $ circleci-bundle-update-pr 'Git username' 'Git email address' master develop topic

## Contributing

1. Fork it ( https://github.com/masutaka/circleci-bundle-update-pr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[gem-badge]: https://badge.fury.io/rb/circleci-bundle-update-pr.svg
[gem-link]: http://badge.fury.io/rb/circleci-bundle-update-pr
