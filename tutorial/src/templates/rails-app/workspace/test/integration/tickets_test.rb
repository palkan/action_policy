require "test_helper"

class TicketsTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @ticket = tickets(:password_reset)
  end

  test "redirects to sign in when not authenticated" do
    get tickets_path
    assert_redirected_to new_session_path
  end

  test "index lists tickets" do
    sign_in @alice
    get tickets_path
    assert_response :success
    assert_text @ticket.title
  end

  test "show displays ticket" do
    sign_in @alice
    get ticket_path(@ticket)
    assert_response :success
    assert_text @ticket.title
  end

  test "new renders form" do
    sign_in @alice
    get new_ticket_path
    assert_response :success
    assert_text "New Ticket"
  end

  test "create saves ticket" do
    sign_in @alice
    assert_difference "Ticket.count" do
      post tickets_path, params: {ticket: {title: "New ticket", description: "Details"}}
    end
    assert_redirected_to ticket_path(Ticket.last)
  end

  test "create with blank title fails" do
    sign_in @alice
    assert_no_difference "Ticket.count" do
      post tickets_path, params: {ticket: {title: "", description: "Details"}}
    end
    assert_response :unprocessable_entity
  end

  test "edit renders form" do
    sign_in @alice
    get edit_ticket_path(@ticket)
    assert_response :success
    assert_text "Edit Ticket"
  end

  test "update changes ticket" do
    sign_in @alice
    patch ticket_path(@ticket), params: {ticket: {title: "Updated"}}
    assert_response :redirect
    assert_equal "Updated", @ticket.reload.title
  end

  test "destroy removes ticket" do
    sign_in @alice
    assert_difference "Ticket.count", -1 do
      delete ticket_path(@ticket)
    end
    assert_redirected_to tickets_path
  end
end
