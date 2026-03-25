require "test_helper"

class TicketPolicyTest < ActiveSupport::TestCase
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
  end

  test "show? allows everyone" do
    policy = TicketPolicy.new(tickets(:password_reset), user: @alice)
    assert policy.apply(:show?)
  end

  test "manage? allows ticket owner" do
    policy = TicketPolicy.new(tickets(:password_reset), user: @alice)
    assert policy.apply(:manage?)
  end

  test "manage? denies non-owner customer" do
    policy = TicketPolicy.new(tickets(:password_reset), user: users(:dana))
    assert_not policy.apply(:manage?)
  end

  test "manage? allows assigned agent" do
    policy = TicketPolicy.new(tickets(:billing), user: @bob)
    assert policy.apply(:manage?)
  end

  test "manage? denies unassigned agent" do
    policy = TicketPolicy.new(tickets(:password_reset), user: @bob)
    assert_not policy.apply(:manage?)
  end

  test "manage? allows admin" do
    policy = TicketPolicy.new(tickets(:password_reset), user: @charlie)
    assert policy.apply(:manage?)
  end

  test "destroy? denies non-admin" do
    policy = TicketPolicy.new(tickets(:password_reset), user: @alice)
    assert_not policy.apply(:destroy?)
  end

  test "destroy? allows admin" do
    policy = TicketPolicy.new(tickets(:password_reset), user: @charlie)
    assert policy.apply(:destroy?)
  end

  test "relation_scope returns customer's own tickets" do
    scope = TicketPolicy.new(Ticket, user: @alice).apply_scope(Ticket.all, type: :active_record_relation)
    assert_equal @alice.tickets.count, scope.count
    assert scope.all? { |t| t.user_id == @alice.id }
  end

  test "relation_scope returns agent's assigned and unassigned tickets" do
    scope = TicketPolicy.new(Ticket, user: @bob).apply_scope(Ticket.all, type: :active_record_relation)
    assert scope.all? { |t| t.agent_id == @bob.id || t.agent_id.nil? }
  end

  test "relation_scope returns all tickets for admin" do
    scope = TicketPolicy.new(Ticket, user: @charlie).apply_scope(Ticket.all, type: :active_record_relation)
    assert_equal Ticket.count, scope.count
  end
end
