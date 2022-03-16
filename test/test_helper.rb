# frozen_string_literal: true

require "i18n"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

ENV["RAILS_ENV"] = "test"

begin
  require "debug" unless ENV["CI"]
rescue LoadError
end

ENV["RUBY_NEXT_TRANSPILE_MODE"] = "rewrite"
ENV["RUBY_NEXT_EDGE"] = "1"
ENV["RUBY_NEXT_PROPOSED"] = "1"
require "ruby-next/language/runtime" unless ENV["CI"]

require "action_policy"

ActionPolicy::PrettyPrint.ignore_expressions << /\bjard\b/

Dir["#{__dir__}/helpers/**/*.rb"].sort.each { |f| require f }
Dir["#{__dir__}/stubs/**/*.rb"].sort.each { |f| require f }

require "minitest/autorun"
