# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"
  SimpleCov.start do
    enable_coverage :branch

    add_filter "/spec/"
    add_filter "/lib/generators/"
  end

  require "simplecov-lcov"
  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/lcov.info"
  end

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])
end

require "i18n"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

ENV["RAILS_ENV"] = "test"

begin
  require "debug" unless ENV["CI"]
rescue LoadError
end

ENV["RUBY_NEXT_TRANSPILE_MODE"] = "rewrite"
ENV["RUBY_NEXT_EDGE"] = "1"
require "ruby-next/language/runtime" unless ENV["CI"]

require "logger"

require "action_policy"

ActionPolicy::PrettyPrint.ignore_expressions << /\bjard\b/

Dir["#{__dir__}/helpers/**/*.rb"].sort.each { |f| require f }
Dir["#{__dir__}/stubs/**/*.rb"].sort.each { |f| require f }

require "minitest/autorun"
