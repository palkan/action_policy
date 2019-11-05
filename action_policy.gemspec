# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "action_policy/version"

Gem::Specification.new do |spec|
  spec.name          = "action_policy"
  spec.version       = ActionPolicy::VERSION
  spec.authors       = ["Vladimir Dementyev"]
  spec.email         = ["dementiev.vm@gmail.com"]

  spec.summary       = "Authorization framework for Ruby/Rails application"
  spec.description   = "Authorization framework for Ruby/Rails application"
  spec.homepage      = "https://github.com/palkan/action_policy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/action_policy/issues",
    "changelog_uri" => "https://github.com/palkan/action_policy/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://actionpolicy.evilmartians.io/",
    "homepage_uri" => "https://actionpolicy.evilmartians.io/",
    "source_code_uri" => "http://github.com/palkan/action_policy"
  }

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4.0"

  spec.add_development_dependency "ammeter", "~> 1.1.3"
  spec.add_development_dependency "bundler", ">= 1.15"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "rubocop", "~> 0.67.0"
  spec.add_development_dependency "rubocop-md", "~> 0.2"
  spec.add_development_dependency "standard", "~> 0.0.39"
  spec.add_development_dependency "benchmark-ips", "~> 2.7.0"
  spec.add_development_dependency "i18n"
end
