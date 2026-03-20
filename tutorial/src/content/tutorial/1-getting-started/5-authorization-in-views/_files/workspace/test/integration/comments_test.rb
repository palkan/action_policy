require "test_helper"

class CommentsTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @ticket = tickets(:password_reset)
    @alices_comment = comments(:alice_on_password_reset)
  end

  test "create adds comment to ticket" do
    sign_in @alice
    assert_difference "Comment.count" do
      post ticket_comments_path(@ticket), params: {comment: {body: "A comment"}}
    end
    assert_redirected_to ticket_path(@ticket)
  end

  # === Authorization: destroy ===

  test "author can delete their comment" do
    sign_in @alice
    assert_difference "Comment.count", -1 do
      delete ticket_comment_path(@ticket, @alices_comment)
    end
    assert_redirected_to ticket_path(@ticket)
  end

  test "other user cannot delete someone else's comment" do
    sign_in @bob
    assert_no_difference "Comment.count" do
      delete ticket_comment_path(@ticket, @alices_comment)
    end
    assert_redirected_to ticket_path(@ticket)
    assert_equal "Not authorized", flash[:alert]
  end

  test "admin can delete any comment" do
    sign_in @charlie
    assert_difference "Comment.count", -1 do
      delete ticket_comment_path(@ticket, @alices_comment)
    end
    assert_redirected_to ticket_path(@ticket)
  end
end
