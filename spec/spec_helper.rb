# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "action_policy"
begin
  require "pry-byebug"
rescue LoadError
end

require "ammeter"

require_relative "../test/stubs/user"

require "action_policy/rspec"

RSpec.configure do |config|
  config.mock_with :rspec

  config.order = :random
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = "tmp/.rspec-status"
end
