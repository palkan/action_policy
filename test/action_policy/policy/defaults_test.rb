# frozen_string_literal: true

require "test_helper"

class DefaultsTestPolicy < ActionPolicy::Base
end

class TestPolicyDefaults < Minitest::Test
  def setup
    @policy = DefaultsTestPolicy.new user: User.new("john")
  end

  def test_crud_rules
    refute @policy.index?
    refute @policy.create?
    refute @policy.manage?
  end

  def test_aliases
    assert_equal :manage?, @policy.resolve_rule(:destroy?)
    assert_equal :create?, @policy.resolve_rule(:new?)
  end
end
