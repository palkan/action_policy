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
    @type == 'a' ? LookupAPolicy : LookupBPolicy
  end
end

class LookupC
  def self.policy_class
    LookupAPolicy
  end
end

class LookupAPolicy; end
class LookupBPolicy; end

class TestLookupChain < Minitest::Test
  def test_not_found
    e = assert_raises(ActionPolicy::NotFound) do
      ActionPolicy.lookup(nil)
    end

    assert_match /Couldn't find policy class for/, e.message
  end

  def test_instance_defined
    a = LookupB.new('a')
    policy = ActionPolicy.lookup(a)

    assert_equal LookupAPolicy, policy

    b = LookupB.new('b')
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
end
