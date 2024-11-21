# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "debug", platform: :mri unless ENV["CI"] == "true"

gem "method_source"
gem "prism"

gem 'sqlite3', "~> 2.0", platform: :mri
gem 'activerecord-jdbcsqlite3-adapter', '~> 50.0', platform: :jruby
gem 'jdbc-sqlite3', platform: :jruby

eval_gemfile "gemfiles/rubocop.gemfile"

local_gemfile = File.join(__dir__, "Gemfile.local")

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
else
  gem "rails", "~> 8.0"
end

if ENV["COVERAGE"] == "true"
  gem "simplecov"
  gem "simplecov-lcov"
end
