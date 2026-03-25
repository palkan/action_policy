require "test_helper"

class CommentsTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @ticket = tickets(:password_reset)
  end

  test "create adds comment to ticket" do
    sign_in @alice
    assert_difference "Comment.count" do
      post ticket_comments_path(@ticket), params: {comment: {body: "A comment"}}
    end
    assert_redirected_to ticket_path(@ticket)
    assert_equal "A comment", @ticket.comments.last.body
    assert_equal @alice, @ticket.comments.last.user
  end

  test "create with blank body redirects with alert" do
    sign_in @alice
    assert_no_difference "Comment.count" do
      post ticket_comments_path(@ticket), params: {comment: {body: ""}}
    end
    assert_redirected_to ticket_path(@ticket)
    follow_redirect!
    assert_text "blank"
  end

  test "create internal comment" do
    sign_in @bob
    post ticket_comments_path(@ticket), params: {comment: {body: "Internal note", internal: true}}
    assert @ticket.comments.last.internal?
  end

  test "destroy removes comment" do
    sign_in @alice
    comment = comments(:alice_on_password_reset)
    assert_difference "Comment.count", -1 do
      delete ticket_comment_path(@ticket, comment)
    end
    assert_redirected_to ticket_path(@ticket)
  end
end
