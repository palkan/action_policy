# frozen_string_literal: true

require "test_helper"

class TestScopingPolicy < Minitest::Test
  class UserPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization
    include ActionPolicy::Policy::Scoping

    authorize :user

    scope_for :data do |users|
      next users if user.admin?

      users.reject(&:admin?)
    end

    scope_for :data, :with_options do |users, with_admins:|
      next users if with_admins

      users.reject(&:admin?)
    end
  end

  class GuestPolicy < UserPolicy
    # override parent class scope
    scope_for :data do |_|
      []
    end

    scope_for :data, :own do |users|
      users.select { |u| u.name == user.name }
    end
  end

  def setup
    @users = [User.new("jack"), User.new("admin")]
  end

  attr_reader :users

  def test_missing_scope_type
    policy = UserPolicy.new(user: User.new("admin"))

    e = assert_raises ActionPolicy::UnknownScopeType do
      policy.apply_scope(users, type: :datta)
    end

    assert_includes e.message, "Unknown policy scope type :datta"
    assert_includes e.message, "Did you mean? data" if
      defined?(::DidYouMean::SpellChecker)
  end

  def test_default_scope
    policy = UserPolicy.new(user: User.new("guest"))

    scoped_users = policy.apply_scope(users, type: :data)

    assert_equal 1, scoped_users.size
    assert_equal "jack", scoped_users.first.name
  end

  def test_subpolicy_scope
    policy = GuestPolicy.new(user: User.new("admin"))

    scoped_users = policy.apply_scope(users, type: :data)

    assert_equal 0, scoped_users.size
  end

  def test_named_scope
    policy = GuestPolicy.new(user: User.new("admin"))

    scoped_users = policy.apply_scope(users, type: :data, name: :own)

    assert_equal 1, scoped_users.size
    assert_equal "admin", scoped_users.first.name
  end

  def test_missing_named_scope
    policy = UserPolicy.new(user: User.new("admin"))

    e = assert_raises ActionPolicy::UnknownNamedScope do
      policy.apply_scope(users, type: :data, name: :own)
    end

    assert_equal(
      "Unknown named scope :own for type :data for TestScopingPolicy::UserPolicy",
      e.message
    )
  end

  def test_missing_named_scope_suggestion
    policy = GuestPolicy.new(user: User.new("admin"))

    e = assert_raises ActionPolicy::UnknownNamedScope do
      policy.apply_scope(users, type: :data, name: :owned)
    end

    assert_includes(
      e.message,
      "Unknown named scope :owned for type :data for TestScopingPolicy::GuestPolicy"
    )

    assert_includes e.message, "Did you mean? own" if
      defined?(::DidYouMean::SpellChecker)
  end

  def test_missing_scope_options
    policy = UserPolicy.new(user: User.new("guest"))

    e = assert_raises ArgumentError do
      policy.apply_scope(users, type: :data, name: :with_options)
    end

    assert_includes e.message, "missing keyword: with_admins"
  end

  def test_scope_options
    policy = UserPolicy.new(user: User.new("guest"))

    scoped_users = policy.apply_scope(users,
                                      type: :data,
                                      name: :with_options,
                                      scope_options: {with_admins: false})

    assert_equal 1, scoped_users.size
    assert_equal "jack", scoped_users.first.name

    scoped_users = policy.apply_scope(users,
                                      type: :data,
                                      name: :with_options,
                                      scope_options: {with_admins: true})

    assert_equal 2, scoped_users.size
  end
end

class TestPolicyScopeMatchers < Minitest::Test
  class Payload < Struct.new(:value, :level); end

  class MyPayload < Payload; end

  class UserPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization
    include ActionPolicy::Policy::Scoping

    authorize :user

    scope_matcher :hash_or_array, ->(v) { v.is_a?(Array) || v.is_a?(Hash) }

    scope_for :hash_or_array do |users|
      next users if user.admin?

      # handle hash values or arrays
      if users.is_a?(Array)
        users.reject(&:admin?)
      else
        users.reject { |_, v| v.admin? }
      end
    end

    scope_for :payload do |payload|
      next payload if user.admin?

      next payload if payload.level.zero?

      nil
    end
  end

  class GuestPolicy < UserPolicy
    scope_matcher :payload, Payload
  end

  def test_proc_matcher
    users = [User.new("jack"), User.new("admin")]

    policy = UserPolicy.new(user: User.new("guest"))

    scope_type = policy.resolve_scope_type(users)

    assert_equal :hash_or_array, scope_type
  end

  def test_class_matcher
    payload = Payload.new("a", 2)
    policy = GuestPolicy.new(user: User.new("guest"))

    scope_type = policy.resolve_scope_type(payload)

    assert_equal :payload, scope_type
  end

  def test_no_matching_type
    payload = Payload.new("a", 2)
    policy = UserPolicy.new(user: User.new("guest"))

    e = assert_raises ActionPolicy::UnrecognizedScopeTarget do
      policy.resolve_scope_type(payload)
    end

    assert_includes e.message,
                    "Couldn't infer scope type for TestPolicyScopeMatchers::Payload instance"
  end
end

class TestNestedPolicyScope < Minitest::Test
  class Post < Struct.new(:user); end

  class UserPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization
    include ActionPolicy::Policy::Scoping

    authorize :user

    scope_matcher :array, Array

    scope_for :array do |users|
      next users if user.admin?

      users.reject(&:admin?)
    end
  end

  class PostPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization
    include ActionPolicy::Policy::Scoping

    authorize :user, :all_users

    scope_for :array do |posts|
      accessible_users = authorized_scope(all_users, with: UserPolicy)
      posts.select { |post| post.user.nil? || accessible_users.include?(post.user) }
    end
  end

  def test_nested_policy_authorized_scope
    user = User.new("jack")
    admin = User.new("admin")

    users = [user, admin]

    post = Post.new(user)
    post2 = Post.new(admin)
    post3 = Post.new(nil)

    posts = [post, post2, post3]

    policy = PostPolicy.new(user: User.new("guest"), all_users: users)

    scoped_posts = policy.apply_scope(posts, type: :array)

    assert_equal 2, scoped_posts.size
    assert_includes scoped_posts, post
    assert_includes scoped_posts, post3

    policy = PostPolicy.new(user: User.new("admin"), all_users: users)

    scoped_posts = policy.apply_scope(posts, type: :array)

    assert_equal 3, scoped_posts.size
  end
end
