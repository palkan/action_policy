# frozen_string_literal: true

require "test_helper"

class FailuresTestPolicy < ActionPolicy::Base
end

class TestFailuresPolicy < Minitest::Test
  def setup
    @policy = FailuresTestPolicy.new nil
  end

  def test_apply_success
    assert @policy.apply(:index?)
    assert @policy.reasons.empty?
  end

  def test_apply_failure
    refute @policy.apply(:manage?)
    assert @policy.reasons.empty?
  end
end

class UserFailuresPolicy < ActionPolicy::Base; end

class ComplexFailuresTestPolicy < ActionPolicy::Base
  verify :user

  def kill?
    (user.name == "admin") && allowed_to?(:manage?, user, with: UserFailuresPolicy)
  end

  def save?
    allowed_to?(:kill?) || allowed_to?(:create?, user)
  end

  def feed?
    false
  end
end

class TestComplexFailuresPolicy < Minitest::Test
  User = Struct.new(:name)

  class UserPolicy < ActionPolicy::Base; end

  def test_and_condition_first_main_clause_failure
    policy = ComplexFailuresTestPolicy.new nil, user: User.new("guest")

    refute policy.apply(:kill?)
    reasons = policy.reasons

    assert_equal 0, reasons.size
  end

  def test_and_condition_nested_check_failure
    policy = ComplexFailuresTestPolicy.new nil, user: User.new("admin")

    refute policy.apply(:kill?)
    reasons = policy.reasons

    assert_equal 1, reasons.size
    assert_equal UserFailuresPolicy, reasons.first.policy
    assert_equal :manage?, reasons.first.rule
  end

  def test_or_condition
    policy = ComplexFailuresTestPolicy.new nil, user: User.new("guest")

    refute policy.apply(:save?)
    reasons = policy.reasons

    assert_equal 2, reasons.size

    assert_equal ComplexFailuresTestPolicy, reasons.first.policy
    assert_equal :kill?, reasons.first.rule

    assert_equal UserPolicy, reasons.last.policy
    assert_equal :create?, reasons.last.rule
  end

  def test_or_condition_2
    policy = ComplexFailuresTestPolicy.new nil, user: User.new("admin")

    refute policy.apply(:save?)
    reasons = policy.reasons

    assert_equal 2, reasons.size

    assert_equal ComplexFailuresTestPolicy, reasons.first.policy
    assert_equal :kill?, reasons.first.rule

    assert_equal UserPolicy, reasons.last.policy
    assert_equal :create?, reasons.last.rule
  end
end
