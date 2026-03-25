require "test_helper"

class TicketsTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @alices_ticket = tickets(:password_reset)
    @bobs_assigned_ticket = tickets(:billing)
  end

  test "redirects to sign in when not authenticated" do
    get tickets_path
    assert_redirected_to new_session_path
  end

  test "index lists tickets" do
    sign_in @alice
    get tickets_path
    assert_response :success
  end

  test "show displays ticket" do
    sign_in @alice
    get ticket_path(@alices_ticket)
    assert_response :success
  end

  test "create saves ticket" do
    sign_in @alice
    assert_difference "Ticket.count" do
      post tickets_path, params: {ticket: {title: "New ticket", description: "Details"}}
    end
    assert_redirected_to ticket_path(Ticket.last)
  end

  # === Authorization: edit/update ===

  test "owner can edit their ticket" do
    sign_in @alice
    get edit_ticket_path(@alices_ticket)
    assert_response :success
  end

  test "owner can update their ticket" do
    sign_in @alice
    patch ticket_path(@alices_ticket), params: {ticket: {title: "Updated"}}
    assert_response :redirect
    assert_equal "Updated", @alices_ticket.reload.title
  end

  test "assigned agent can edit the ticket" do
    sign_in @bob
    get edit_ticket_path(@bobs_assigned_ticket)
    assert_response :success
  end

  test "agent cannot edit a ticket not assigned to them" do
    sign_in @bob
    get edit_ticket_path(@alices_ticket)
    assert_redirected_to tickets_path
    assert_equal "Not authorized", flash[:alert]
  end

  test "agent cannot update a ticket not assigned to them" do
    sign_in @bob
    patch ticket_path(@alices_ticket), params: {ticket: {title: "Hacked"}}
    assert_redirected_to tickets_path
    assert_equal "Not authorized", flash[:alert]
    assert_not_equal "Hacked", @alices_ticket.reload.title
  end

  test "admin can edit any ticket" do
    sign_in @charlie
    get edit_ticket_path(@alices_ticket)
    assert_response :success
  end

  # === Authorization: destroy ===

  test "owner cannot delete their ticket" do
    sign_in @alice
    assert_no_difference "Ticket.count" do
      delete ticket_path(@alices_ticket)
    end
    assert_redirected_to tickets_path
    assert_equal "Not authorized", flash[:alert]
  end

  test "admin can delete a ticket" do
    sign_in @charlie
    assert_difference "Ticket.count", -1 do
      delete ticket_path(@alices_ticket)
    end
    assert_redirected_to tickets_path
  end
end
