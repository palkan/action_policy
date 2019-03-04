# frozen_string_literal: true

require "test_helper"

class AliasesRuleTestPolicy
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Aliases

  default_rule :manage?

  alias_rule :update?, :destroy?, :create?, to: :edit?

  def manage?
  end

  def edit?
  end

  def index?
  end

  class NoDefault < self
    default_rule nil

    alias_rule :index?, :update?, to: :manage?

    def create?
    end
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

  if defined?(::DidYouMean::SpellChecker)
    def test_suggest
      policy = AliasesRuleTestPolicy::NoDefault.new

      e = assert_raises(ActionPolicy::UnknownRule) do
        policy.resolve_rule(:creates?)
      end

      assert_includes e.message, "Did you mean? create?"
    end
  end

  def test_inherited_override
    policy = AliasesRuleTestPolicy::NoDefault.new

    assert_equal :edit?, policy.resolve_rule(:destroy?)
    assert_equal :manage?, policy.resolve_rule(:update?)
    assert_equal :manage?, policy.resolve_rule(:index?)
    assert_equal :create?, policy.resolve_rule(:create?)
  end
end
