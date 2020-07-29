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
  # TODO: Drop after deprecating Rails 4.2
  if defined?(ActiveSupport::Testing::Stream)
    include ActiveSupport::Testing::Stream
  else
    include(Module.new do
      def silence_stream(stream)
        old_stream = stream.dup
        stream.reopen(IO::NULL)
        stream.sync = true
        yield
      ensure
        stream.reopen(old_stream)
        old_stream.close
      end
    end)
  end
end
