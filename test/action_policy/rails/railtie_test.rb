# frozen_string_literal: true

require "test_helper"
require_relative "./dummy/config/environment"

class TestRailtie < Minitest::Test
  def test_default_configuration
    assert_includes ActionController::Base, ActionPolicy::Controller

    assert_equal({user: :current_user}, ActionController::Base.authorization_targets)

    refute ActionPolicy::LookupChain.namespace_cache_enabled?
  end

  def test_cache_store
    Dummy::Application.config.action_policy.cache_store = :memory_store
    assert ActionPolicy.cache_store.is_a?(ActiveSupport::Cache::MemoryStore)
  end
end
