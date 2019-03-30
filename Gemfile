# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "pry-byebug", platform: :mri

gem "method_source"
gem "unparser"

gem 'sqlite3', "~> 1.3.0", platform: :mri
gem 'activerecord-jdbcsqlite3-adapter', '~> 50.0', platform: :jruby
gem 'jdbc-sqlite3', platform: :jruby

local_gemfile = File.join(__dir__, "Gemfile.local")

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
else
  gem "rails", "~> 5.0"
end
