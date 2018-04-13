# frozen_string_literal: true

require "test_helper"

class TestMemoized < Minitest::Test
  class UserPolicy < ::UserPolicy
    class << self
      def policies
        @policies ||= []
      end

      def reset
        @policies = []
      end
    end

    def initialize(*)
      super
      self.class.policies << self
    end
  end

  class User < ::User; end

  class CustomPolicy < UserPolicy; end

  class CacheableUser < User
    def policy_class
      UserPolicy
    end

    def cache_key
      "user/#{name}"
    end
  end

  class ChatChannel
    include ActionPolicy::Behaviour
    include ActionPolicy::Behaviours::Memoized

    attr_reader :user

    authorize :user

    def initialize(name)
      @user = User.new(name)
    end

    def talk(user)
      authorize! user, to: :update?
      "OK"
    end

    def speak(user)
      authorize! user, to: :update?, with: CustomPolicy
      "OK"
    end

    def talk?(user)
      allowed_to?(:talk?, user)
    end
  end

  def setup
    @subject = ChatChannel.new("admin")
  end

  attr_reader :subject

  def teardown
    UserPolicy.reset
    CustomPolicy.reset
  end

  def test_instance_cache
    user = User.new("guest")

    subject.talk(user)
    assert_equal 1, UserPolicy.policies.size

    subject.talk(user)
    assert_equal 1, UserPolicy.policies.size

    subject.talk?(user)
    assert_equal 1, UserPolicy.policies.size
  end

  def test_instance_cache_with_different_policies
    user = User.new("guest")

    subject.talk(user)
    assert_equal 1, UserPolicy.policies.size
    assert_equal 0, CustomPolicy.policies.size

    subject.speak(user)
    assert_equal 1, UserPolicy.policies.size
    assert_equal 1, CustomPolicy.policies.size
  end

  def test_instance_cache_without_cache_key
    subject.talk(User.new("guest"))
    assert_equal 1, UserPolicy.policies.size

    subject.talk(User.new("guest"))
    assert_equal 2, UserPolicy.policies.size
  end

  def test_instance_cache_with_cache_key
    subject.talk(CacheableUser.new("guest"))
    assert_equal 1, UserPolicy.policies.size

    subject.talk(CacheableUser.new("guest"))
    assert_equal 1, UserPolicy.policies.size
  end
end
