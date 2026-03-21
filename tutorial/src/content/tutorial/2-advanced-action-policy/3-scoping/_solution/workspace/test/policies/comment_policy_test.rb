require "test_helper"

class CommentPolicyTest < ActiveSupport::TestCase
  test "create? allows customer on open ticket" do
    ticket = tickets(:password_reset)
    policy = CommentPolicy.new(Comment.new, user: users(:alice), ticket: ticket)
    assert policy.apply(:create?)
  end

  test "create? denies customer on resolved ticket" do
    ticket = tickets(:dark_mode)
    policy = CommentPolicy.new(Comment.new, user: users(:alice), ticket: ticket)
    assert_not policy.apply(:create?)
  end

  test "create? allows agent on resolved ticket" do
    ticket = tickets(:dark_mode)
    policy = CommentPolicy.new(Comment.new, user: users(:bob), ticket: ticket)
    assert policy.apply(:create?)
  end

  test "create? denies without ticket context" do
    policy = CommentPolicy.new(Comment.new, user: users(:alice))
    assert_not policy.apply(:create?)
  end

  test "show? allows non-internal comment for customer" do
    comment = comments(:alice_on_password_reset)
    policy = CommentPolicy.new(comment, user: users(:alice))
    assert policy.apply(:show?)
  end

  test "show? denies internal comment for customer" do
    comment = comments(:bob_internal)
    policy = CommentPolicy.new(comment, user: users(:alice))
    assert_not policy.apply(:show?)
  end

  test "show? allows internal comment for agent" do
    comment = comments(:bob_internal)
    policy = CommentPolicy.new(comment, user: users(:bob))
    assert policy.apply(:show?)
  end

  test "relation_scope hides internal comments from customer" do
    scope = CommentPolicy.new(Comment, user: users(:alice)).apply_scope(Comment.all, type: :relation)
    assert scope.none?(&:internal?)
  end

  test "relation_scope shows all comments to agent" do
    scope = CommentPolicy.new(Comment, user: users(:bob)).apply_scope(Comment.all, type: :relation)
    assert scope.any?(&:internal?)
  end

  test "destroy? allows comment author" do
    comment = comments(:alice_on_password_reset)
    policy = CommentPolicy.new(comment, user: users(:alice))
    assert policy.apply(:destroy?)
  end

  test "destroy? denies non-author" do
    comment = comments(:alice_on_password_reset)
    policy = CommentPolicy.new(comment, user: users(:bob))
    assert_not policy.apply(:destroy?)
  end

  test "destroy? allows admin" do
    comment = comments(:alice_on_password_reset)
    policy = CommentPolicy.new(comment, user: users(:charlie))
    assert policy.apply(:destroy?)
  end
end
