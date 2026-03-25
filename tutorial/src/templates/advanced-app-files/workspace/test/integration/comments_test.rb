require "test_helper"

class CommentsTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @ticket = tickets(:password_reset)
    @comment = comments(:alice_on_password_reset)
  end

  test "create adds comment to ticket" do
    sign_in @alice
    assert_difference "Comment.count" do
      post ticket_comments_path(@ticket), params: {comment: {body: "A comment"}}
    end
    assert_redirected_to ticket_path(@ticket)
  end

  test "destroy authorizes comment" do
    sign_in @alice
    assert_authorized_to(:destroy?, @comment, with: CommentPolicy) do
      delete ticket_comment_path(@ticket, @comment)
    end
  end
end
