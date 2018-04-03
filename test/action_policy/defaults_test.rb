# frozen_string_literal: true

require "test_helper"

class DefaultsTestPolicy < ActionPolicy::Base
end

class TestPolicyDefaults < Minitest::Test
  def setup
    @policy = DefaultsTestPolicy.new nil
  end

  def test_crud_rules
    assert @policy.index?

    refute @policy.create?
    refute @policy.new?

    refute @policy.manage?
  end
end
