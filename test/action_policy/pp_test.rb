# frozen_string_literal: true

require "test_helper"

class PrettyPrintPolicy < ActionPolicy::Base
  def feed?
    (admin? || allowed_to?(:access_feed?)) &&
      (user.name == "Jack" || user.name == "Kate")
  end

  def edit?
    (user.name == "John") && (admin? || access_feed?)
  end

  def access?
    admin? && access_feed?
  end

  def admin?
    user.admin?
  end

  def access_feed?
    true
  end

  def admind?
    binding.irb # rubocop:disable Lint/Debugger
    user.admin?
  end

  def admind_jard?
    jard # rubocop:disable Lint/Debugger
    user.admin?
  end
end

class TestPrettyPrint < Minitest::Test
  def setup
    skip unless ActionPolicy::PrettyPrint.available?
    @user = User.new("Kate")
    @policy = PrettyPrintPolicy.new(user: @user)
  end

  attr_reader :policy

  def test_single_expression_rule
    expected = <<~EXPECTED
      PrettyPrintPolicy#admin?
      ↳ user.admin? #=> false
    EXPECTED

    assert_output(expected) { policy.pp(:admin?) }
  end

  def test_multi_expression_rule
    expected = <<~EXPECTED
      PrettyPrintPolicy#access?
      ↳ admin? #=> false
        AND
        access_feed? #=> true
    EXPECTED

    assert_output(expected) { policy.pp(:access?) }
  end

  def test_multi_expression_with_parentheses
    expected = <<~EXPECTED
      PrettyPrintPolicy#edit?
      ↳ (
          user.name == "John" #=> false
        )
        AND
        (
          admin? #=> false
          OR
          access_feed? #=> true
        )
    EXPECTED

    assert_output(expected) { policy.pp(:edit?) }
  end

  def test_multi_parentheses
    expected = <<~EXPECTED
      PrettyPrintPolicy#feed?
      ↳ (
          admin? #=> false
          OR
          allowed_to?(:access_feed?) #=> true
        )
        AND
        (
          user.name == "Jack" #=> false
          OR
          user.name == "Kate" #=> true
        )
    EXPECTED

    assert_output(expected) { policy.pp(:feed?) }
  end

  def test_single_expression_rule_with_debug
    expected = <<~EXPECTED
      PrettyPrintPolicy#admind?
      ↳ binding.irb #=> <skipped>
      ↳ user.admin? #=> false
    EXPECTED

    assert_output(expected) { policy.pp(:admind?) }
  end

  def test_single_expression_rule_with_jard
    expected = <<~EXPECTED
      PrettyPrintPolicy#admind_jard?
      ↳ jard #=> <skipped>
      ↳ user.admin? #=> false
    EXPECTED

    assert_output(expected) { policy.pp(:admind_jard?) }
  end
end
