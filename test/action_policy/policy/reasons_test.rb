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

    assert_equal({user_failures: [:manage?]}, details)
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

  def test_no_result
    policy = ComplexFailuresTestPolicy.new user: User.new("admin")

    refute policy.save?
    assert_nil policy.result
  end
end

class FailuresWithDetailsPolicy < ActionPolicy::Base
  self.identifier = :detailed

  def kill?
    details[:role] = user.name
    (user.name == "admin") && allowed_to?(:manage?, user, with: UserFailuresPolicy)
  end

  def save?
    allowed_to?(:kill?) || (
      allowed_to?(:create?, user) && check?(:feed?)
    )
  end

  def feed?
    details[:some] = "stuff"
    false
  end
end

class TestFailuresWithDetailsPolicy < Minitest::Test
  User = Struct.new(:name)

  class UserPolicy < ActionPolicy::Base
    self.identifier = :user

    def create?
      check?(:admin?) || check?(:manager?) || check?(:superman?)
    end

    def admin?
      details[:name] = user.name
      user.name == "admin"
    end

    def manager?
      false
    end

    def superman?
      details[:superhero] = "spiderman"
      false
    end
  end

  def test_and_condition_nested_check_details
    policy = FailuresWithDetailsPolicy.new user: User.new("guest")

    refute policy.apply(:save?)

    details = policy.result.reasons.details

    assert_equal({
      detailed: [{kill?: {role: "guest"}}],
      user: [:create?]
    }, details)
  end

  def test_detailed_and_not_detailed_reasons
    policy = UserPolicy.new user: User.new("gusto")

    refute policy.apply(:create?)

    details = policy.result.reasons.details

    assert_equal({
      user: [:manager?, {admin?: {name: "gusto"}, superman?: {superhero: "spiderman"}}]
    }, details)
  end

  def test_multiple_details
    policy = FailuresWithDetailsPolicy.new user: User.new("admin")

    refute policy.apply(:save?)

    details = policy.result.reasons.details

    assert_equal({
      detailed: [{kill?: {role: "admin"}, feed?: {some: "stuff"}}]
    }, details)
  end

  def test_all_details
    policy = UserPolicy.new user: User.new("gusto")

    refute policy.apply(:create?)

    details = policy.result.all_details

    assert_equal({name: "gusto", superhero: "spiderman"}, details)
  end
end
