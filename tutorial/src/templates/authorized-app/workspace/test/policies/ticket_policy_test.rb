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
    other = User.create!(name: "Dave", email_address: "dave@example.org", password: "s3cr3t", role: "customer")
    policy = TicketPolicy.new(tickets(:password_reset), user: other)
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
end
