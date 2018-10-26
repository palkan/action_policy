# frozen_string_literal: true

require "test_helper"
require "action_policy/test_helper"

class TestHelperTest < Minitest::Test
  include ActionPolicy::TestHelper

  class CustomPolicy < ::UserPolicy; end

  class Channel
    include ActionPolicy::Behaviour

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

    def filter(users)
      authorized users, type: :data, with: CustomPolicy
    end

    def filter_with_options(users, with_admins: false)
      authorized users, type: :data, with: CustomPolicy, scope_options: { with_admins: with_admins }
    end

    def own(users)
      authorized users, type: :data, as: :own, with: CustomPolicy
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
                                 scope_options: { with_admins: true }) do
      subject.filter_with_options([user], with_admins: true)
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
                 "from UserPolicy to have been applied"),
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
                 "from UserPolicy to have been applied"),
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
                                   scope_options: { with_admins: false }) do
        subject.filter_with_options([user], with_admins: true)
      end
    end

    assert_match(
      Regexp.new("Expected a scoping named :default for :data type " \
                 "with scope options {:with_admins=>false} " \
                 "from UserPolicy to have been applied"),
      error.message
    )
    assert_match(
      Regexp.new("Registered scopings: .*TestHelperTest::CustomPolicy :default " \
                 "for :data with scope options {:with_admins=>true}"),
      error.message
    )
  end
end
