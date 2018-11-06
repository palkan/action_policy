# frozen_string_literal: true

require "i18n"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

ENV["RAILS_ENV"] = "test"

begin
  require "pry-byebug"
rescue LoadError # rubocop: disable Lint/HandleExceptions
end

require "action_policy"

Dir["#{__dir__}/stubs/**/*.rb"].each { |f| require f }

require "minitest/autorun"
