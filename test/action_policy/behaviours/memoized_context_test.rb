# frozen_string_literal: true

require "test_helper"

class TestMemoizedContext < Minitest::Test
  class ChatPolicy < ActionPolicy::Base
    authorize :user, :account
  end

  class ChatChannel
    include ActionPolicy::Behaviour
    include ActionPolicy::Behaviours::MemoizedContext

    authorize :user
    authorize :account

    attr_reader :user
    attr_writer :account

    def initialize(name)
      @user = User.new(name)
    end

    def account
      @account = @account ? @account.succ : "a"
    end

    def policy_context(**options)
      policy = policy_for(record: nil, with: ChatPolicy, **options)
      policy.authorization_context
    end
  end

  class ChutChannel < ChatChannel
    def authorization_context
      build_authorization_context
    end
  end

  def test_authorization_context_memoized
    channel = ChatChannel.new("guest")

    assert_equal({user: User.new("guest"), account: "a"}, channel.authorization_context)
    assert_equal({user: User.new("guest"), account: "a"}, channel.authorization_context)
    assert_equal({user: User.new("guest"), account: "a"}, channel.policy_context)
  end

  def test_authorization_explicit_context_without_memoization
    channel = ChatChannel.new("guest")

    assert_equal({user: User.new("guest"), account: "z"}, channel.policy_context(context: {account: "z"}))

    channel.account = "x"

    assert_equal({user: User.new("guest"), account: "y"}, channel.authorization_context)
    assert_equal({user: User.new("guest"), account: "y"}, channel.policy_context)

    assert_equal({user: User.new("guest"), account: "z"}, channel.policy_context(context: {account: "z"}))

    assert_equal({user: User.new("guest"), account: "y"}, channel.authorization_context)
    assert_equal({user: User.new("guest"), account: "y"}, channel.policy_context)
  end

  def test_authorization_context_without_memoization
    channel = ChutChannel.new("guest")

    assert_equal({user: User.new("guest"), account: "a"}, channel.authorization_context)
    assert_equal({user: User.new("guest"), account: "b"}, channel.authorization_context)
    assert_equal({user: User.new("guest"), account: "c"}, channel.policy_context)
  end
end
