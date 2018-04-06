# frozen_string_literal: true

require "test_helper"
require "action_policy/test_helper"

class TestNamespaced < Minitest::Test
  include ActionPolicy::TestHelper

  module Admin
    class UserPolicy < ::UserPolicy
      def manage?
        user.admin?
      end
    end
  end

  class CustomPolicy < ::UserPolicy; end

  class Channel
    include ActionPolicy::Behaviour
    include ActionPolicy::Behaviours::Namespaced

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

    def notify_all(account)
      authorize! account, to: :manage?
      "OK"
    end
  end

  module Admin
    class AdminChannel < Channel; end
  end

  def setup
    @user = User.new("guest")
  end

  attr_reader :user

  def test_no_namespace
    subject = Channel.new("guest")

    assert_authorized_to(:manage?, user, with: ::UserPolicy) do
      subject.talk(user)
    end
  end

  def test_namespaced_policy_exists
    subject = Admin::AdminChannel.new("guest")

    assert_authorized_to(:manage?, user, with: Admin::UserPolicy) do
      subject.talk(user)
    end
  end

  def test_explicit_policy
    subject = Admin::AdminChannel.new("guest")

    assert_authorized_to(:manage?, user, with: CustomPolicy) do
      subject.speak(user)
    end
  end

  def test_when_namespaced_policy_missing
    account = Account.new("admin")
    subject = Admin::AdminChannel.new("guest")

    assert_authorized_to(:manage?, account, with: ::AccountPolicy) do
      subject.notify_all(account)
    end
  end
end
