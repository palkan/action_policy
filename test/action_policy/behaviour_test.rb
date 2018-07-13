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

      authorize! user, to: :update?

      "OK"
    end

    def talk?(name)
      user = User.new(name)
      allowed_to?(:talk?, user)
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

class TestAuthorizedBehaviour < Minitest::Test
  class ChatChannel
    include ActionPolicy::Behaviour

    attr_reader :user, :data

    authorize :user

    def initialize(name, data)
      @user = User.new(name)
      @data = data
    end

    def all
      authorized(data, :data)
    end

    def my
      authorized(data, :data, as: :own)
    end

    def implicit_authorization_target
      User
    end
  end

  def setup
    @users = [User.new("jack"), User.new("admin")]
  end

  attr_reader :users

  def test_default_authorized
    chat = ChatChannel.new("guest", users)

    scoped_users = chat.all

    assert_equal 1, scoped_users.size
    assert_equal "jack", scoped_users.first.name

    chat = ChatChannel.new("admin", users)

    scoped_users = chat.all

    assert_equal 2, scoped_users.size
  end

  def test_named_authorized
    chat = ChatChannel.new("guest", users)

    scoped_users = chat.my

    assert_equal 0, scoped_users.size

    chat = ChatChannel.new("admin", users)

    scoped_users = chat.my

    assert_equal 1, scoped_users.size
    assert_equal "admin", scoped_users.first.name
  end
end
