require "test_helper"

class CommentPolicyTest < ActiveSupport::TestCase
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
