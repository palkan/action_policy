# frozen_string_literal: true

require "test_helper"
require_relative "active_record_helper"
require "stubs/in_memory_cache"

class TestRailsPolicyCache < Minitest::Test
  class UserPolicy < ActionPolicy::Base
    authorize :user

    class << self
      attr_accessor :managed_count

      def reset
        @managed_count = 0
      end
    end

    reset

    authorize :user

    cache :manage?

    def manage?
      self.class.managed_count += 1

      user.admin? && !record.admin?
    end
  end

  def setup
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    ActionPolicy.cache_store = InMemoryCache.new
    @guest = AR::User.create!(role: "guest")
  end

  attr_reader :guest

  def teardown
    UserPolicy.reset
    ActionPolicy.cache_store = nil
    ActiveRecord::Base.connection.rollback_transaction
  end

  def test_cache_with_versioning
    user = AR::User.create!(role: "admin")

    policy = UserPolicy.new guest, user: user

    assert policy.apply(:manage?)
    assert policy.apply(:manage?)

    assert_equal 1, UserPolicy.managed_count

    policy_2 = UserPolicy.new guest, user: user

    assert policy_2.apply(:manage?)

    assert_equal 1, UserPolicy.managed_count

    user.touch

    policy_3 = UserPolicy.new guest, user: user

    assert policy_3.apply(:manage?)

    assert_equal 2, UserPolicy.managed_count

    guest.touch

    policy_4 = UserPolicy.new guest, user: user

    assert policy_4.apply(:manage?)

    assert_equal 3, UserPolicy.managed_count
  end
end
