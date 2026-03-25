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
