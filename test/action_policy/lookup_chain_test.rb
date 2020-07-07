# frozen_string_literal: true

require "test_helper"

class LookupA
  class NestedLookup; end
  class NestedLookupPolicy; end
end

class LookupB
  def initialize(type)
    @type = type
  end

  def policy_class
    @type == "a" ? LookupAPolicy : LookupBPolicy
  end
end

class LookupC
  def self.policy_class
    LookupAPolicy
  end
end

class LookupAPolicy; end
class LookupBPolicy; end
class LookupBsPolicy; end

module LookupNamespace
  class LookupAPolicy; end

  module NestedNamespace; end
end

class LookupAA
  def self.policy_name
    :LookupAPolicy
  end
end

class TestLookupChain < Minitest::Test
  def test_not_found
    e = assert_raises(ActionPolicy::NotFound) do
      ActionPolicy.lookup(nil)
    end

    assert_match %r{Couldn't find policy class for}, e.message
  end

  def test_symbol
    assert_equal(
      LookupAPolicy,
      ActionPolicy.lookup(:lookup_a)
    )
  end

  def test_symbol_exact_match
    assert_equal(
      LookupBsPolicy,
      ActionPolicy.lookup(:lookup_bs)
    )
  end

  def test_symbol_namespaced
    assert_equal(
      LookupNamespace::LookupAPolicy,
      ActionPolicy.lookup(:lookup_a, namespace: LookupNamespace)
    )
    assert_equal(
      LookupBPolicy,
      ActionPolicy.lookup(:lookup_b, namespace: LookupNamespace)
    )
  end

  def test_instance_defined
    a = LookupB.new("a")
    policy = ActionPolicy.lookup(a)

    assert_equal LookupAPolicy, policy

    b = LookupB.new("b")
    policy = ActionPolicy.lookup(b)

    assert_equal LookupBPolicy, policy
  end

  def test_class_defined
    c = LookupC.new

    assert_equal LookupAPolicy, ActionPolicy.lookup(c)
  end

  def test_inferred
    a = LookupA.new

    assert_equal LookupAPolicy, ActionPolicy.lookup(a)
  end

  def test_inferred_namespaced
    a_nested = LookupA::NestedLookup.new

    assert_equal LookupA::NestedLookupPolicy, ActionPolicy.lookup(a_nested)
  end

  def test_with_namespace
    a = LookupA.new

    assert_equal(
      LookupNamespace::LookupAPolicy,
      ActionPolicy.lookup(a, namespace: LookupNamespace)
    )
  end

  def test_namespace_fallback_to_global
    b = LookupB.new("b")

    assert_equal(
      LookupBPolicy,
      ActionPolicy.lookup(b, namespace: LookupNamespace.name)
    )
  end

  def test_namespace_fallback_to_intermidiate_namespace
    a = LookupA.new

    assert_equal(
      LookupNamespace::LookupAPolicy,
      ActionPolicy.lookup(a, namespace: LookupNamespace::NestedNamespace)
    )
  end

  def test_lookup_namespace_by_policy_name
    a = LookupAA.new

    assert_equal(
      LookupNamespace::LookupAPolicy,
      ActionPolicy.lookup(a, namespace: LookupNamespace::NestedNamespace)
    )
  end
end
