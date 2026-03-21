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

  test "index scopes tickets for customer" do
    sign_in @alice
    get tickets_path
    assert_response :success
    assert_text "Can not reset my password"
    assert_text "Billing discrepancy"
    assert_no_match "Search is extremely slow", response.body
  end

  test "index shows assigned and unassigned tickets for agent" do
    sign_in users(:bob)
    get tickets_path
    assert_response :success
    assert_text "Billing discrepancy"
    assert_text "Can not log in from mobile"
    assert_text "Search is extremely slow"
  end

  test "show authorizes and displays ticket" do
    sign_in @alice
    assert_authorized_to(:show?, @ticket, with: TicketPolicy) do
      get ticket_path(@ticket)
    end
    assert_response :success
  end

  test "show hides internal comments from customer" do
    sign_in @alice
    get ticket_path(tickets(:billing))
    assert_response :success
    assert_no_match "Confirmed duplicate charge", response.body
  end

  test "show displays internal comments for agent" do
    sign_in users(:bob)
    get ticket_path(tickets(:billing))
    assert_response :success
    assert_text "Confirmed duplicate charge"
  end

  test "create saves ticket" do
    sign_in @alice
    assert_difference "Ticket.count" do
      post tickets_path, params: {ticket: {title: "New ticket", description: "Details"}}
    end
    assert_redirected_to ticket_path(Ticket.last)
  end

  test "edit authorizes ticket" do
    sign_in @alice
    assert_authorized_to(:manage?, @ticket, with: TicketPolicy) do
      get edit_ticket_path(@ticket)
    end
  end

  test "update authorizes ticket" do
    sign_in @alice
    assert_authorized_to(:manage?, @ticket, with: TicketPolicy) do
      patch ticket_path(@ticket), params: {ticket: {title: "Updated"}}
    end
  end

  test "destroy authorizes ticket" do
    sign_in @alice
    assert_authorized_to(:destroy?, @ticket, with: TicketPolicy) do
      delete ticket_path(@ticket)
    end
  end
end
