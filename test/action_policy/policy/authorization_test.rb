# frozen_string_literal: true

require "test_helper"

class AuthorizeTestPolicy
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Authorization
  authorize :account
end

class SubAuthorizeTestPolicy < AuthorizeTestPolicy
  authorize :role, allow_nil: true
end

class OptionalRoleTestPolicy
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Authorization

  authorize :role, optional: true
end

class AuthorizationTest < Minitest::Test
  def test_target_is_missing
    e = assert_raises ActionPolicy::AuthorizationContextMissing do
      AuthorizeTestPolicy.new
    end

    assert_equal "Missing policy authorization context: account", e.message
  end

  def test_target_is_present
    policy = AuthorizeTestPolicy.new(account: "EvilMartians")
    assert_equal "EvilMartians", policy.account
  end

  def test_target_is_nil
    assert_raises ActionPolicy::AuthorizationContextMissing do
      AuthorizeTestPolicy.new(account: nil)
    end
  end

  def test_target_inheritance
    e = assert_raises ActionPolicy::AuthorizationContextMissing do
      SubAuthorizeTestPolicy.new(account: "EvilMartians")
    end

    assert_equal "Missing policy authorization context: role", e.message

    policy = SubAuthorizeTestPolicy.new(account: "EvilMartians", role: "human")
    assert_equal "EvilMartians", policy.account
    assert_equal "human", policy.role
  end

  def test_context_allow_nil
    policy = SubAuthorizeTestPolicy.new(account: "EvilMartians", role: nil)
    assert_equal "EvilMartians", policy.account
    assert_nil policy.role
  end

  def test_context_optional
    policy = OptionalRoleTestPolicy.new
    assert_nil policy.role
  end

  def test_context_optional_with_value
    policy = OptionalRoleTestPolicy.new(role: "human")
    assert_equal "human", policy.role
  end
end

class ProxyAuthorizationToSubPoliciesTest < Minitest::Test
  class TestPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization

    authorize :user, :role

    def manage?
      role == "admin" || user.admin?
    end
  end

  class SubTestPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization

    authorize :user, :role

    def manage?
      allowed_to?(:manage?, with: TestPolicy)
    end
  end

  def test_passing_context_in_policy_for
    policy = SubTestPolicy.new(user: User.new("guest"), role: "admin")

    assert_equal "admin", policy.authorization_context[:role]
    assert_equal "guest", policy.authorization_context[:user].name
    assert policy.apply(:manage?)
  end
end
