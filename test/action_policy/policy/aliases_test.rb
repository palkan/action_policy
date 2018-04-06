# frozen_string_literal: true

require "test_helper"

class AliasesRuleTestPolicy
  include ActionPolicy::Policy::Core
  prepend ActionPolicy::Policy::Aliases

  default_rule :manage?

  alias_rule :update?, :destroy?, to: :edit?

  def manage?; end

  def edit?; end

  class NoDefault < self
    default_rule nil

    alias_rule :update?, to: :manage?
  end
end

class TestPolicyAliasesRule < Minitest::Test
  def setup
    @policy = AliasesRuleTestPolicy.new
  end

  attr_reader :policy

  def test_default_rule
    assert_equal :manage?, policy.resolve_rule(:show?)
    assert_equal :edit?, policy.resolve_rule(:edit?)
  end

  def test_alias_rule
    assert_equal :edit?, policy.resolve_rule(:update?)
    assert_equal :edit?, policy.resolve_rule(:destroy?)
    assert_equal :edit?, policy.resolve_rule(:edit?)
  end

  def test_without_default
    policy = AliasesRuleTestPolicy::NoDefault.new

    assert_equal :manage?, policy.resolve_rule(:manage?)

    assert_raises(ActionPolicy::UnknownRule) do
      policy.resolve_rule(:show?)
    end
  end

  def test_inherited_override
    policy = AliasesRuleTestPolicy::NoDefault.new

    assert_equal :edit?, policy.resolve_rule(:destroy?)
    assert_equal :manage?, policy.resolve_rule(:update?)
  end
end
