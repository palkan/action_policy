# frozen_string_literal: true

require "test_helper"

class TestBehaviour < Minitest::Test
  # Kind of ActionCable
  class ChatChannel
    include ActionPolicy::Behaviour

    attr_reader :user

    authorize :user

    def initialize(name)
      @user = User.new(name)
    end

    def talk(name)
      user = User.new(name)

      authorize! user, to: :update

      "OK"
    end

    def talk?(name)
      user = User.new(name)
      allowed_to?(:talk, user)
    end
  end

  def test_authorize_succeed
    chat = ChatChannel.new("admin")

    assert "OK", chat.talk("guest")
  end

  def test_authorize_failed
    chat = ChatChannel.new("guest")

    e = assert_raises(ActionPolicy::Unauthorized) do
      chat.talk("admin")
    end

    assert_equal UserPolicy, e.policy
    assert_equal :manage?, e.rule
  end

  def test_allowed_to
    assert ChatChannel.new("admin").talk?("guest")
    refute ChatChannel.new("guest").talk?("admin")
  end
end
