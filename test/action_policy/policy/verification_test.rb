# frozen_string_literal: true

require "test_helper"

class VerifyTestPolicy < ActionPolicy::Base
  verify :account
end

class SubVerifyTestPolicy < VerifyTestPolicy
  verify :role, allow_nil: true
end

class VerificationTest < Minitest::Test
  def test_target_is_missing
    e = assert_raises ActionPolicy::VerificationContextMissing do
      VerifyTestPolicy.new
    end

    assert_equal "Missing policy verification context: account", e.message
  end

  def test_target_is_present
    policy = VerifyTestPolicy.new(account: "EvilMartians")
    assert_equal "EvilMartians", policy.account
  end

  def test_target_is_nil
    assert_raises ActionPolicy::VerificationContextMissing do
      VerifyTestPolicy.new(account: nil)
    end
  end

  def test_target_inheritance
    e = assert_raises ActionPolicy::VerificationContextMissing do
      SubVerifyTestPolicy.new(account: "EvilMartians")
    end

    assert_equal "Missing policy verification context: role", e.message

    policy = SubVerifyTestPolicy.new(account: "EvilMartians", role: "human")
    assert_equal "EvilMartians", policy.account
    assert_equal "human", policy.role
  end

  def test_context_allow_nil
    policy = SubVerifyTestPolicy.new(account: "EvilMartians", role: nil)
    assert_equal "EvilMartians", policy.account
    assert_nil policy.role
  end
end
