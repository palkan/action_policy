# frozen_string_literal: true

require "test_helper"

class TestScopingPolicy < Minitest::Test
  class UserPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization
    include ActionPolicy::Policy::Scoping

    authorize :user

    scope_for :data do |users|
      next users if user.admin?

      users.reject(&:admin?)
    end
  end

  class GuestPolicy < UserPolicy
    # override parent class scope
    scope_for :data do |_|
      []
    end

    scope_for :data, :own do |users|
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
      policy.apply_scope(users, type: :datta)
    end

    assert_includes e.message, "Unknown policy scope type: datta"
    assert_includes e.message, "Did you mean? data" if
      defined?(::DidYouMean::SpellChecker)
  end

  def test_default_scope
    policy = UserPolicy.new(user: User.new("guest"))

    scoped_users = policy.apply_scope(users, type: :data)

    assert_equal 1, scoped_users.size
    assert_equal "jack", scoped_users.first.name
  end

  def test_subpolicy_scope
    policy = GuestPolicy.new(user: User.new("admin"))

    scoped_users = policy.apply_scope(users, type: :data)

    assert_equal 0, scoped_users.size
  end

  def test_named_scope
    policy = GuestPolicy.new(user: User.new("admin"))

    scoped_users = policy.apply_scope(users, type: :data, name: :own)

    assert_equal 1, scoped_users.size
    assert_equal "admin", scoped_users.first.name
  end

  def test_missing_named_scope
    policy = UserPolicy.new(user: User.new("admin"))

    e = assert_raises ActionPolicy::UnknownNamedScope do
      policy.apply_scope(users, type: :data, name: :own)
    end

    assert_equal "Unknown named scope :own for type :data", e.message
  end

  def test_missing_named_scope_suggestion
    policy = GuestPolicy.new(user: User.new("admin"))

    e = assert_raises ActionPolicy::UnknownNamedScope do
      policy.apply_scope(users, type: :data, name: :owned)
    end

    assert_includes e.message, "Unknown named scope :owned for type :data"
    assert_includes e.message, "Did you mean? own" if
      defined?(::DidYouMean::SpellChecker)
  end
end

class TestPolicyScopeMatchers < Minitest::Test
  class Payload < Struct.new(:value, :level); end

  class MyPayload < Payload; end

  class UserPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization
    include ActionPolicy::Policy::Scoping

    authorize :user

    scope_matcher :hash_or_array, ->(v) { v.is_a?(Array) || v.is_a?(Hash) }

    scope_for :hash_or_array do |users|
      next users if user.admin?

      # handle hash values or arrays
      if users.is_a?(Array)
        users.reject(&:admin?)
      else
        users.reject { |_, v| v.admin? }
      end
    end

    scope_for :payload do |payload|
      next payload if user.admin?

      next payload if payload.level.zero?

      nil
    end
  end

  class GuestPolicy < UserPolicy
    scope_matcher :payload, Payload
  end

  def test_proc_matcher
    users = [User.new("jack"), User.new("admin")]

    policy = UserPolicy.new(user: User.new("guest"))

    scoped_users = policy.apply_scope(users)

    assert_equal 1, scoped_users.size
    assert_equal "jack", scoped_users.first.name

    policy = UserPolicy.new(user: User.new("admin"))

    scoped_users = policy.apply_scope(users)
    assert_equal 2, scoped_users.size

    users_hash = { a: User.new("jack"), b: User.new("admin") }

    policy = UserPolicy.new(user: User.new("guest"))

    scoped_users = policy.apply_scope(users_hash)

    assert_equal({ a: User.new("jack") }, scoped_users)
  end

  def test_class_matcher
    payload = Payload.new("a", 2)
    payload2 = Payload.new("a", 0)

    policy = GuestPolicy.new(user: User.new("guest"))
    scoped_payload = policy.apply_scope(payload)

    assert_nil scoped_payload

    scoped_payload = policy.apply_scope(payload2)

    assert_equal payload2, scoped_payload

    policy = GuestPolicy.new(user: User.new("admin"))
    scoped_payload = policy.apply_scope(payload)

    assert_equal payload, scoped_payload
  end

  def test_no_matching_type
    payload = Payload.new("a", 2)
    policy = UserPolicy.new(user: User.new("guest"))

    e = assert_raises ActionPolicy::UnrecognizedScopeTarget do
      policy.apply_scope(payload)
    end

    assert_includes e.message,
                    "Couldn't infer scope type for TestPolicyScopeMatchers::Payload instance"
  end
end
