# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "action_policy"
begin
  require "pry-byebug"
rescue LoadError
end

require_relative "../test/stubs/user"

require "ammeter"
require "action_policy/rspec"

require File.expand_path("dummy/config/environment", __dir__)

RSpec.configure do |config|
  config.mock_with :rspec

  config.order = :random
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = "tmp/.rspec-status"

  # For silence_stream
  include ActiveSupport::Testing::Stream
end
