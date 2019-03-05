# frozen_string_literal: true

module QueriesAssertions
  class Collector
    def initialize(pattern)
      @pattern = pattern
    end

    def call
      @queries = []
      ActiveSupport::Notifications
        .subscribed(method(:callback), "sql.active_record") do
        yield
      end
      @queries
    end

    def callback(_name, _start, _finish, _message_id, values)
      return if %w[CACHE SCHEMA].include? values[:name]

      @queries << values[:sql] if @pattern.nil? || (values[:sql] =~ @pattern)
    end
  end

  def assert_queries(num = 1, pattern = nil)
    collector = Collector.new(pattern)
    queries = collector.call { yield }
    assert_equal num, queries.size, queries.size.zero? ? "No queries were made" : "The following queries were made: #{queries.join(", ")}"
  end

  def assert_no_queries(pattern = nil)
    assert_queries 0, pattern, &Proc.new
  end
end
