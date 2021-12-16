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

  spec.files = Dir.glob("lib/**/*") + Dir.glob("lib/.rbnext/**/*") + %w[README.md LICENSE.txt CHANGELOG.md] + %w[config/rubocop-rspec.yml]

  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/action_policy/issues",
    "changelog_uri" => "https://github.com/palkan/action_policy/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://actionpolicy.evilmartians.io/",
    "homepage_uri" => "https://actionpolicy.evilmartians.io/",
    "source_code_uri" => "http://github.com/palkan/action_policy"
  }

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.6.0"

  # When gem is installed from source, we add `ruby-next` as a dependency
  # to auto-transpile source files during the first load
  if ENV["RELEASING_GEM"].nil? && File.directory?(File.join(__dir__, ".git"))
    spec.add_runtime_dependency "ruby-next", ">= 0.13.3"
  else
    spec.add_dependency "ruby-next-core", ">= 0.13.3"
  end

  spec.add_development_dependency "ammeter", "~> 1.1.3"
  spec.add_development_dependency "bundler", ">= 1.15"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", ">= 3.9"
  spec.add_development_dependency "benchmark-ips", "~> 2.7.0"
  spec.add_development_dependency "i18n"
end
