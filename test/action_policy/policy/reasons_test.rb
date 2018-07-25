# frozen_string_literal: true

require "test_helper"

class FailuresTestPolicy
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Reasons

  def index?
    true
  end

  def manage?
    false
  end
end

class TestFailuresPolicy < Minitest::Test
  def setup
    @policy = FailuresTestPolicy.new
  end

  def test_apply_success
    assert @policy.apply(:index?)
    assert @policy.result.reasons.empty?
  end

  def test_apply_failure
    refute @policy.apply(:manage?)
    assert @policy.result.reasons.empty?
  end
end

class UserFailuresPolicy < ActionPolicy::Base; end

class ComplexFailuresTestPolicy < ActionPolicy::Base
  self.identifier = :complex

  def kill?
    (user.name == "admin") && allowed_to?(:manage?, user, with: UserFailuresPolicy)
  end

  def save?
    allowed_to?(:kill?) || (allowed_to?(:create?, user) && check?(:feed?))
  end

  def feed?
    false
  end
end

class TestComplexFailuresPolicy < Minitest::Test
  User = Struct.new(:name)

  class UserPolicy < ActionPolicy::Base
    self.identifier = :user

    def create?
      user.name == "admin"
    end
  end

  def test_and_condition_first_main_clause_failure
    policy = ComplexFailuresTestPolicy.new user: User.new("guest")

    refute policy.apply(:kill?)
    assert policy.result.reasons.empty?
  end

  def test_and_condition_nested_check_failure
    policy = ComplexFailuresTestPolicy.new user: User.new("admin")

    refute policy.apply(:kill?)

    details = policy.result.reasons.details

    assert_equal({ user_failures: [:manage?] }, details)
  end

  def test_or_condition
    policy = ComplexFailuresTestPolicy.new user: User.new("guest")

    refute policy.apply(:save?)

    details = policy.result.reasons.details

    assert_equal({
                   complex: [:kill?],
                   user: [:create?]
                 }, details)
  end

  def test_or_condition_2
    policy = ComplexFailuresTestPolicy.new user: User.new("admin")

    refute policy.apply(:save?)

    details = policy.result.reasons.details

    assert_equal({
                   complex: [:kill?, :feed?]
                 }, details)
  end
end
