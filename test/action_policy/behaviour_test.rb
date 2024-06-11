# frozen_string_literal: true

require "test_helper"

class TestBehaviour < Minitest::Test
  # Kind of ActionCable
  class ChatChannel
    include ActionPolicy::Behaviour

    attr_reader :user

    authorize :user

    def initialize(name = nil)
      @user = User.new(name) unless name.nil?
    end

    def talk(name)
      user = User.new(name)

      authorize! user, to: :update?

      "OK"
    end

    def talk_as(name, another_user)
      user = User.new(name)

      authorize! user, to: :update?, context: {user: another_user}

      "OK"
    end

    def talk?(name)
      user = User.new(name)
      allowed_to?(:talk?, user)
    end

    def talk_allowance(name)
      user = User.new(name)
      allowance_to(:talk?, user)
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

  def test_authorize_explicit_context
    chat = ChatChannel.new
    admin = User.new("admin")

    assert "OK", chat.talk_as("guest", admin)
  end

  def test_allowance
    result = ChatChannel.new("admin").talk_allowance("guest")

    assert result.success?
    assert_equal :manage?, result.rule

    result = ChatChannel.new("admin").talk_allowance("admin")

    assert result.fail?
    assert_equal :manage?, result.rule
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

    scoped_users = chat.authorized_scope(users, type: :data)

    assert_equal 1, scoped_users.size
    assert_equal "jack", scoped_users.first.name

    chat = ChatChannel.new("admin")

    scoped_users = chat.authorized_scope(users, type: :data)

    assert_equal 2, scoped_users.size
  end

  def test_default_authorized_with_scope_options
    chat = ChatChannel.new("guest")

    scoped_users = chat.authorized_scope(users, type: :data)

    assert_equal 1, scoped_users.size
    assert_equal "jack", scoped_users.first.name

    scoped_users = chat.authorized_scope(users, type: :data, scope_options: {with_admins: true})

    assert_equal 2, scoped_users.size
  end

  def test_named_authorized
    chat = ChatChannel.new("guest")

    scoped_users = chat.authorized_scope(users, type: :data, as: :own)

    assert_equal 0, scoped_users.size

    chat = ChatChannel.new("admin")

    scoped_users = chat.authorized_scope(users, type: :data, as: :own)

    assert_equal 1, scoped_users.size
    assert_equal "admin", scoped_users.first.name
  end

  def test_infer_policy_from_target
    chat = ChatChannel.new("jack")

    assert_raises(ActionPolicy::UnknownScopeType) do
      chat.authorized_scope(users, type: :users)
    end

    users.define_singleton_method(:policy_class) { CustomPolicy }

    scoped_users = chat.authorized_scope(users, type: :users)
    assert_equal "jack", scoped_users.first.name

    chat = ChatChannel.new("admin")

    scoped_users = chat.authorized_scope(users, type: :users)

    assert_equal 1, scoped_users.size
    assert_equal "admin", scoped_users.first.name
  end
end

class TestMissingImplicitTarget < Minitest::Test
  class ChatChannel
    include ActionPolicy::Behaviour

    def ping
      authorize! to: :ping?
      "pong"
    end

    # Regression test for https://github.com/palkan/action_policy/issues/179
    def pong
      user = User.new("admin")
      user.define_singleton_method(:==) { |*| true }

      authorize! user, to: :show?, context: {user: user}
      "ping"
    end

    def implicit_authorization_target
      nil
    end
  end

  def test_implicit_authorization_target_is_included_in_failure_message
    channel = ChatChannel.new

    e = assert_raises ActionPolicy::NotFound do
      channel.ping
    end

    assert_includes e.message, "Couldn't find implicit authorization target " \
                               "for TestMissingImplicitTarget::ChatChannel. " \
                               "Please, provide policy class explicitly using `with` option or " \
                               "define the `implicit_authorization_target` method."
  end

  def test_overriden_equality
    channel = ChatChannel.new

    assert_equal "ping", channel.pong
  end
end

class TestNoTarget < Minitest::Test
  class ChatChannel
    include ActionPolicy::Behaviour

    attr_reader :user

    authorize :user

    def initialize(name)
      @user = User.new(name)
    end
  end

  def test_no_record_provided
    channel = ChatChannel.new("guest")

    assert_raises ActionPolicy::NotFound do
      channel.authorize! to: :ping
    end
  end

  def test_no_record_provided_but_with_policy
    channel = ChatChannel.new("guest")

    channel.authorize! to: :show?, with: UserPolicy
    assert channel.allowed_to? :show?, with: UserPolicy
  end
end

class TestDefaultAuthorizationPolicy < Minitest::Test
  class UserPolicy
    include ActionPolicy::Policy::Core

    def ping?
      true
    end
  end

  class GuestPolicy < UserPolicy
    def ping?
      false
    end
  end

  class RoomChannel
    include ActionPolicy::Behaviour

    attr_reader :user

    def initialize(user = nil)
      @user = user
    end

    def ping
      authorize! self, to: :ping?
      "pong"
    end

    def default_authorization_policy_class
      user ? UserPolicy : GuestPolicy
    end
  end

  def test_default_authorization_policy_class
    guest_channel = RoomChannel.new

    assert_raises ActionPolicy::Unauthorized do
      guest_channel.ping
    end

    user_channel = RoomChannel.new(User.new("bob"))

    assert_equal "pong", user_channel.ping
  end
end

class TestStrictNamespaceAuthorizationPolicy < Minitest::Test
  class RoomChannelPolicy
    include ActionPolicy::Policy::Core

    def ping?
      true
    end
  end

  module Admin
    class RoomChannel
      include ActionPolicy::Behaviour
      include ActionPolicy::Behaviours::Namespaced

      def ping
        authorize! self, to: :ping?
        "pong"
      end

      def policy_name
        "RoomChannelPolicy"
      end

      def authorization_strict_namespace
        true
      end
    end
  end

  def test_strict_namespace_authorization_policy_class
    admin_channel = Admin::RoomChannel.new

    assert_raises ActionPolicy::NotFound do
      admin_channel.ping
    end
  end
end

class TestAuthorizationContext < Minitest::Test
  class AdminPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization

    authorize :user

    def show? = user.name == "admin" || record != "admin"
  end

  class ChatPolicy < AdminPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization

    authorize :user, :account

    def speak? = user.name == account
  end

  class ChatChannel
    include ActionPolicy::Behaviour

    authorize :user
    authorize :account

    attr_reader :user

    def initialize(name)
      @user = User.new(name)
    end

    def speak(word, to:)
      # Use explicit context to skip memoization
      authorize! to, to: :show?, with: AdminPolicy, context: {}

      @explicit_account = to
      # This will use implicit context (shouldn't be memoized)
      # See https://github.com/palkan/action_policy/issues/265
      authorize! to: :speak?

      "I have spoken #{word} to ##{to}"
    end

    def account
      return @explicit_account if defined?(@explicit_account)
      @account = @account ? @account.succ : "a"
    end

    def implicit_authorization_target = self

    def policy_class = ChatPolicy
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
  end

  def test_authorization_context_without_memoization
    channel = ChutChannel.new("guest")

    assert_equal({user: User.new("guest"), account: "a"}, channel.authorization_context)
    assert_equal({user: User.new("guest"), account: "b"}, channel.authorization_context)
  end

  def test_authorization_context_with_explicit_context
    memoize_free_channel = ChutChannel.new("pilot")
    assert_equal "I have spoken yohanga to #pilot", memoize_free_channel.speak("yohanga", to: "pilot")

    channel = ChatChannel.new("bart")
    assert_equal "I have spoken karamba to #bart", channel.speak("karamba", to: "bart")
  end
end
