# frozen_string_literal: true

require "test_helper"

class InMemoryCache
  attr_accessor :store

  def initialize
    self.store = {}
  end

  def fetch(key, **_options)
    return store[key] if store.key?(key)

    store[key] = yield
  end
end

class TestCache < Minitest::Test
  class TestPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization
    include ActionPolicy::Policy::Cache

    class << self
      attr_accessor :managed_count, :shown_count

      def reset
        @managed_count = 0
        @shown_count = 0
      end
    end

    authorize :user

    cache :manage?

    def manage?
      self.class.managed_count ||= 0
      self.class.managed_count += 1

      user.admin? && !record.admin?
    end

    def show?
      self.class.shown_count ||= 0
      self.class.shown_count += 1

      user.admin? || !record.admin?
    end
  end

  class MultipleContextPolicy < TestPolicy
    authorize :account

    cache :show?
  end

  class CacheableUser < User
    def policy_class
      UserPolicy
    end

    def policy_cache_key
      "user/#{name}"
    end

    def admin?
      name.start_with?("admin")
    end
  end

  def setup
    ActionPolicy.cache_store = InMemoryCache.new
    @guest = CacheableUser.new("guest")
  end

  def teardown
    TestPolicy.reset
    MultipleContextPolicy.reset
    ActionPolicy.cache_store = nil
  end

  attr_reader :guest

  def test_cache
    user = CacheableUser.new("admin")

    policy = TestPolicy.new guest, user: user

    assert policy.apply(:manage?)
    assert policy.apply(:manage?)
    assert policy.apply(:show?)
    assert policy.apply(:show?)

    assert_equal 1, TestPolicy.managed_count
    assert_equal 2, TestPolicy.shown_count

    policy_2 = TestPolicy.new guest, user: user

    assert policy_2.apply(:manage?)
    assert policy_2.apply(:show?)

    assert_equal 1, TestPolicy.managed_count
    assert_equal 3, TestPolicy.shown_count
  end

  def test_cache_with_different_records
    user = CacheableUser.new("admin")

    policy = TestPolicy.new guest, user: user

    assert policy.apply(:manage?)

    assert_equal 1, TestPolicy.managed_count

    policy_2 = TestPolicy.new CacheableUser.new("guest_2"), user: user

    assert policy_2.apply(:manage?)
    assert_equal 2, TestPolicy.managed_count
  end

  def test_cache_with_different_contexts
    user = CacheableUser.new("admin")

    policy = TestPolicy.new guest, user: user

    assert policy.apply(:manage?)

    assert_equal 1, TestPolicy.managed_count

    policy_2 = TestPolicy.new guest, user: CacheableUser.new("admin_2")

    assert policy_2.apply(:manage?)
    assert_equal 2, TestPolicy.managed_count
  end

  def test_with_multiple_contexts
    user = CacheableUser.new("admin")

    policy = MultipleContextPolicy.new guest, user: user, account: "test"

    assert policy.apply(:manage?)
    assert policy.apply(:manage?)
    assert policy.apply(:show?)
    assert policy.apply(:show?)

    assert_equal 1, MultipleContextPolicy.managed_count
    assert_equal 1, MultipleContextPolicy.shown_count

    policy_2 = MultipleContextPolicy.new guest, user: CacheableUser.new("admin"), account: :test

    assert policy_2.apply(:manage?)
    assert policy_2.apply(:show?)

    assert_equal 1, MultipleContextPolicy.managed_count
    assert_equal 1, MultipleContextPolicy.shown_count
  end

  def test_with_different_multiple_contexts
    user = CacheableUser.new("admin")

    policy = MultipleContextPolicy.new guest, user: user, account: "test"

    assert policy.apply(:manage?)
    assert policy.apply(:manage?)

    assert_equal 1, MultipleContextPolicy.managed_count

    policy_2 = MultipleContextPolicy.new guest, user: CacheableUser.new("admin"), account: "test_2"

    assert policy_2.apply(:manage?)
    assert_equal 2, MultipleContextPolicy.managed_count
  end
end
