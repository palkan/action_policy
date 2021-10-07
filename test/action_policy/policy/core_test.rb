# frozen_string_literal: true

require "test_helper"

class CoreTestPolicy
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Aliases

  def index?
    true
  end

  def update?
    allow! if record[:editable]
    false
  end

  def destroy?
    deny! if record[:undeletable]
    true
  end

  alias_rule :show?, to: :index?
end

class TestPolicyCore < Minitest::Test
  def setup
    @record = {}
    @policy = CoreTestPolicy.new @record
  end

  def test_apply
    assert @policy.apply(:index?)
    refute @policy.apply(:update?)
    assert @policy.apply(:destroy?)
  end

  def test_alias_rule_apply
    assert @policy.apply(:show?)
  end

  def test_allow_deny
    @record[:undeletable] = true
    @record[:editable] = true

    assert @policy.apply(:update?)
    refute @policy.apply(:destroy?)
  end
end
