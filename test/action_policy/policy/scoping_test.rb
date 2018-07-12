# frozen_string_literal: true

require "test_helper"

class TestScopingPolicy < Minitest::Test
  class UserPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization
    include ActionPolicy::Policy::Scoping

    authorize :user

    authorized :scope do |users|
      next users if user.admin?

      users.reject(&:admin?)
    end
  end

  class GuestPolicy < UserPolicy
    # override parent class scope
    authorized :scope do |_|
      []
    end

    authorized :scope, :own do |users|
      users.select { |u| u.name == user.name }
    end
  end

  def setup
    @users = [User.new("jack"), User.new("admin")]
  end

  attr_reader :users

  def test_missing_scope_type
    policy = UserPolicy.new(user: User.new("admin"))

    e = assert_raises ActionPolicy::UnknownScopeType do
      policy.apply_scope(users, :test)
    end

    assert_equal "Unknown policy scope type: test", e.message
  end

  def test_default_scope
    policy = UserPolicy.new(user: User.new("guest"))

    scoped_users = policy.apply_scope(users, :scope)

    assert_equal 1, scoped_users.size
    assert_equal "jack", scoped_users.first.name
  end

  def test_subpolicy_scope
    policy = GuestPolicy.new(user: User.new("admin"))

    scoped_users = policy.apply_scope(users, :scope)

    assert_equal 0, scoped_users.size
  end

  def test_named_scope
    policy = GuestPolicy.new(user: User.new("admin"))

    scoped_users = policy.apply_scope(users, :scope, as: :own)

    assert_equal 1, scoped_users.size
    assert_equal "admin", scoped_users.first.name
  end

  def test_missing_named_scope
    policy = UserPolicy.new(user: User.new("admin"))

    e = assert_raises ActionPolicy::UnknownNamedScope do
      policy.apply_scope(users, :scope, as: :own)
    end

    assert_equal "Unknown named scope :own for type :scope", e.message
  end
end
