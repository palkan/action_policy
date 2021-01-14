# frozen_string_literal: true

require "test_helper"
require_relative "./dummy/config/environment"
require_relative "active_record_helper"

require "action_policy/ext/policy_cache_key"
using ActionPolicy::Ext::PolicyCacheKey

class TestRailtie < Minitest::Test
  include QueriesAssertions

  def test_default_configuration
    assert(ActionController::Base <= ActionPolicy::Controller, "#{ActionController::Base.ancestors} must include ActionPolicy::Controller")

    if ::Rails::VERSION::MAJOR >= 5
      assert(ActionController::API <= ActionPolicy::Controller, "#{ActionController::API.ancestors} must include ActionPolicy::Controller")
    end

    assert_equal({user: :current_user}, ActionController::Base.authorization_targets)

    refute ActionPolicy::LookupChain.namespace_cache_enabled?
  end

  def test_cache_store
    Dummy::Application.config.action_policy.cache_store = :memory_store
    assert ActionPolicy.cache_store.is_a?(ActiveSupport::Cache::MemoryStore)
  end

  def test_active_record_extensions
    relation = AR::User.all
    assert_no_queries do
      was_key = relation._policy_cache_key
      assert_equal was_key, relation._policy_cache_key
    end
  end
end
