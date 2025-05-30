# frozen_string_literal: true

require "test_helper"
require "action_policy/test_helper"

class TestHelperTest < Minitest::Test
  include ActionPolicy::TestHelper

  class CustomPolicy < ::UserPolicy
    authorize :all_users, optional: true

    scope_for :data, :all do |users|
      all_users ? users : []
    end
  end

  class Channel
    include ActionPolicy::Behaviour

    attr_reader :user

    authorize :user

    def initialize(name)
      @user = User.new(name)
    end

    def talk(user)
      authorize! user, context: {admin: true}, to: :update?
      "OK"
    end

    def speak(user)
      authorize! user, context: {admin: true}, to: :update?, with: CustomPolicy
      "OK"
    end

    def filter(users)
      authorized_scope users, type: :data, with: CustomPolicy
    end

    def filter_with_options(users, with_admins: false)
      authorized_scope users, type: :data, with: CustomPolicy, scope_options: {with_admins: with_admins}
    end

    def own(users)
      authorized_scope users, type: :data, as: :own, with: CustomPolicy
    end

    def filter_with_context(users, context:)
      authorized_scope users, type: :data, as: :all, with: CustomPolicy, context: context
    end
  end

  def setup
    @subject = Channel.new("admin")
    @user = User.new("guest")
  end

  attr_reader :subject, :user

  def test_assert_authorized_to
    assert_authorized_to(:manage?, user, with: ::UserPolicy) do
      subject.talk(user)
    end
  end

  def test_assert_authorized_to_without_policy
    assert_authorized_to(:manage?, user) do
      subject.talk(user)
    end
  end

  def test_assert_authorized_to_with_custom_policy
    assert_authorized_to(:manage?, user, with: CustomPolicy) do
      subject.speak(user)
    end
  end

  def test_assert_authorized_to_with_context
    assert_authorized_to(:manage?, user, context: {admin: true}) do
      subject.talk(user)
    end
  end

  def test_assert_authorized_to_with_context_and_custom_policy
    assert_authorized_to(:manage?, user, context: {admin: true}, with: CustomPolicy) do
      subject.speak(user)
    end
  end

  def test_assert_authorized_to_raised_when_policy_mismatch
    error = assert_raises Minitest::Assertion do
      assert_authorized_to(:manage?, user) do
        subject.speak(user)
      end
    end

    assert_match(%r{Expected.+to be authorized with UserPolicy#manage?}, error.message)
  end

  def test_assert_have_authorized_scope
    assert_have_authorized_scope(type: :data, with: CustomPolicy) do
      subject.filter([user])
    end
  end

  def test_assert_have_authorized_scope_with_name
    assert_have_authorized_scope(type: :data, with: CustomPolicy, as: :own) do
      subject.own([user])
    end
  end

  def test_assert_have_authorized_scope_with_options
    assert_have_authorized_scope(type: :data, with: CustomPolicy,
      scope_options: {with_admins: true}) do
      subject.filter_with_options([user], with_admins: true)
    end
  end

  def test_assert_have_authorized_scope_with_target_block
    assert_have_authorized_scope(type: :data, with: CustomPolicy) do
      subject.filter([user])
    end.with_target do |target|
      assert_equal [user], target
    end
  end

  def test_assert_have_authorized_scope_with_context
    assert_have_authorized_scope(type: :data, as: :all, with: CustomPolicy, context: {all_users: false}) do
      subject.filter_with_context([user], context: {all_users: false})
    end
  end

  def test_assert_have_authorized_scope_raised_when_policy_mismatch
    error = assert_raises Minitest::Assertion do
      assert_have_authorized_scope(type: :data, with: ::UserPolicy) do
        subject.filter([user])
      end
    end

    assert_match(
      Regexp.new("Expected a scoping named :default for :data type without scope options " \
                 "and without context from UserPolicy to have been applied"),
      error.message
    )
  end

  def test_assert_have_authorized_scope_raised_when_scope_name_mismatch
    error = assert_raises Minitest::Assertion do
      assert_have_authorized_scope(type: :data, with: ::UserPolicy, as: :own) do
        subject.filter([user])
      end
    end

    assert_match(
      Regexp.new("Expected a scoping named :own for :data type without scope options " \
                 "and without context from UserPolicy to have been applied"),
      error.message
    )
    assert_match(
      %r{Registered scopings: .*CustomPolicy :default for :data without scope options},
      error.message
    )
  end

  def test_assert_have_authorized_scope_raised_when_scope_options_mismatch
    error = assert_raises Minitest::Assertion do
      assert_have_authorized_scope(type: :data, with: ::UserPolicy,
        scope_options: {with_admins: false}) do
        subject.filter_with_options([user], with_admins: true)
      end
    end

    assert_match(
      Regexp.new("Expected a scoping named :default for :data type " \
                 "with scope options {:?with_admins(=>|: )false} " \
                 "and without context from UserPolicy to have been applied"),
      error.message
    )
    assert_match(
      Regexp.new("Registered scopings: .*TestHelperTest::CustomPolicy :default " \
                 "for :data with scope options {:?with_admins(=>|: )true}"),
      error.message
    )
  end

  def test_assert_have_authorized_scope_raised_when_context_mismatch
    error = assert_raises Minitest::Assertion do
      assert_have_authorized_scope(type: :data, as: :all, with: CustomPolicy, context: {all_users: false}) do
        subject.filter_with_context([user], context: {all_users: true})
      end
    end

    assert_match(
      Regexp.new("Expected a scoping named :all for :data type without scope options " \
                 "and with context: {:?all_users(=>|: )false} from TestHelperTest::CustomPolicy to have been applied"),
      error.message
    )
  end
end
