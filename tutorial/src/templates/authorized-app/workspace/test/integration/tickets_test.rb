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
  end

  test "show authorizes and displays ticket" do
    sign_in @alice
    assert_authorized_to(:show?, @ticket, with: TicketPolicy) do
      get ticket_path(@ticket)
    end
    assert_response :success
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
