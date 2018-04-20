# frozen_string_literal: true

require "test_helper"
require "active_support"
require "action_policy/rails/policy/instrumentation"

class TestRailsInstrumentation < Minitest::Test
  class TestPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Cache
    include ActionPolicy::Policy::Rails::Instrumentation

    cache :manage?

    def manage?
      true
    end

    def show?
      false || record
    end

    def authorization_context
      {}
    end
  end

  def setup
    ActionPolicy.cache_store = InMemoryCache.new
    @events = []

    ActiveSupport::Notifications.subscribe(/action_policy\./) do |event, *, data|
      @events << [event, data]
    end
  end

  def teardown
    ActionPolicy.cache_store = nil
  end

  attr_reader :events

  def test_instrument_apply
    policy = TestPolicy.new false

    refute policy.apply(:show?)

    assert_equal 1, events.size

    event, data = events.pop

    assert_equal "action_policy.apply", event
    assert_equal TestPolicy.name, data[:policy]
    assert_equal "show?", data[:rule]
    refute data[:cached]
  end

  def test_instrument_cached_apply
    policy = TestPolicy.new true

    assert policy.apply(:manage?)

    assert_equal 1, events.size

    event, data = events.pop

    assert_equal "action_policy.apply", event
    assert_equal TestPolicy.name, data[:policy]
    assert_equal "manage?", data[:rule]
    assert_equal false, data[:cached]

    assert policy.apply(:manage?)

    assert_equal 1, events.size

    _event_2, data_2 = events.pop

    assert_equal true, data_2[:cached]
  end
end
