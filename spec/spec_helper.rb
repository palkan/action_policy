# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "action_policy"
begin
  require "pry-byebug"
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

require_relative "../test/stubs/user"

require "action_policy/rspec"

RSpec.configure do |config|
  config.mock_with :rspec

  config.order = :random
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
