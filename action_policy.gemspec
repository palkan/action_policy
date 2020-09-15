# frozen_string_literal: true

require_relative "lib/action_policy/version"

Gem::Specification.new do |spec|
  spec.name = "action_policy"
  spec.version = ActionPolicy::VERSION
  spec.authors = ["Vladimir Dementyev"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "Authorization framework for Ruby/Rails application"
  spec.description = "Authorization framework for Ruby/Rails application"
  spec.homepage = "https://github.com/palkan/action_policy"
  spec.license = "MIT"

  spec.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]

  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/action_policy/issues",
    "changelog_uri" => "https://github.com/palkan/action_policy/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://actionpolicy.evilmartians.io/",
    "homepage_uri" => "https://actionpolicy.evilmartians.io/",
    "source_code_uri" => "http://github.com/palkan/action_policy"
  }

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "ruby-next-core", ">= 0.10.0"

  spec.add_development_dependency "ammeter", "~> 1.1.3"
  spec.add_development_dependency "bundler", ">= 1.15"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", ">= 3.9"
  spec.add_development_dependency "benchmark-ips", "~> 2.7.0"
  spec.add_development_dependency "i18n"
end
