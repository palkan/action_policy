# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

begin
  require "pry-byebug"
rescue LoadError # rubocop: disable Lint/HandleExceptions
end

require "action_policy"

require "minitest/autorun"
