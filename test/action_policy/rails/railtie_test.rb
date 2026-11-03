# frozen_string_literal: true

require "test_helper"
require_relative "dummy/config/environment"
require_relative "active_record_helper"

require "action_policy/ext/policy_cache_key"
using ActionPolicy::Ext::PolicyCacheKey

class TestRailtie < Minitest::Test
  include QueriesAssertions

  def test_default_configuration
    assert(ActionController::Base <= ActionPolicy::Controller, "#{ActionController::Base.ancestors} must include ActionPolicy::Controller")

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

class TestActiveRecordPolicyCacheKey < Minitest::Test
  def setup
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    @user = AR::User.create!(name: "Jack")
  end

  def teardown
    ActiveRecord::Base.connection.rollback_transaction
  end

  attr_reader :user

  class PartialUserPolicy < ActionPolicy::Base
    authorize :user

    def show? = true
  end

  class UsersController < ActionController::Base
    authorize :user, through: :current_user

    def current_user = AR::User.first
  end

  def test_partially_selected_record
    partial_user = AR::User.select(:id, :name).find(user.id)

    assert UsersController.new.allowed_to?(:show?, partial_user, with: PartialUserPolicy)
  end

  def test_partially_selected_records_do_not_share_a_cache_entry
    refute_equal(
      AR::User.select(:id, :name).find(user.id).policy_cache_key,
      AR::User.select(:id, :name).find(user.id).policy_cache_key
    )
  end
end
