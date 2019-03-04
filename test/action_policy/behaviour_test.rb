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

    attr_reader :user

    authorize :user

    def initialize(name)
      @user = User.new(name)
    end

    def implicit_authorization_target
      User
    end
  end

  class CustomPolicy < UserPolicy
    scope_for :users do |arr|
      arr.select { |u| u.name == user.name }
    end
  end

  def setup
    @users = [User.new("jack"), User.new("admin")]
  end

  attr_reader :users

  def test_default_authorized
    chat = ChatChannel.new("guest")

    scoped_users = chat.authorized(users, type: :data)

    assert_equal 1, scoped_users.size
    assert_equal "jack", scoped_users.first.name

    chat = ChatChannel.new("admin")

    scoped_users = chat.authorized(users, type: :data)

    assert_equal 2, scoped_users.size
  end

  def test_default_authorized_with_scope_options
    chat = ChatChannel.new("guest")

    scoped_users = chat.authorized(users, type: :data)

    assert_equal 1, scoped_users.size
    assert_equal "jack", scoped_users.first.name

    scoped_users = chat.authorized(users, type: :data, scope_options: {with_admins: true})

    assert_equal 2, scoped_users.size
  end

  def test_named_authorized
    chat = ChatChannel.new("guest")

    scoped_users = chat.authorized(users, type: :data, as: :own)

    assert_equal 0, scoped_users.size

    chat = ChatChannel.new("admin")

    scoped_users = chat.authorized(users, type: :data, as: :own)

    assert_equal 1, scoped_users.size
    assert_equal "admin", scoped_users.first.name
  end

  def test_infer_policy_from_target
    chat = ChatChannel.new("jack")

    assert_raises(ActionPolicy::UnknownScopeType) do
      chat.authorized(users, type: :users)
    end

    users.define_singleton_method(:policy_class) { CustomPolicy }

    scoped_users = chat.authorized(users, type: :users)
    assert_equal "jack", scoped_users.first.name

    chat = ChatChannel.new("admin")

    scoped_users = chat.authorized(users, type: :users)

    assert_equal 1, scoped_users.size
    assert_equal "admin", scoped_users.first.name
  end
end
