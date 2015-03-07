# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'circleci/bundle/update/pr/version'

Gem::Specification.new do |spec|
  spec.name          = "circleci-bundle-update-pr"
  spec.version       = Circleci::Bundle::Update::Pr::VERSION
  spec.authors       = ["Takashi Masuda"]
  spec.email         = ["masutaka.net@gmail.com"]
  spec.summary       = %q{Create GitHub PullRequest of bundle update in CircleCI}
  spec.description   = %q{A script for continues bundle update. Use in CircleCI}
  spec.homepage      = "https://github.com/masutaka/circleci-bundle-update-pr"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'octokit', '~> 3.8'
  spec.add_dependency 'compare_linker'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
