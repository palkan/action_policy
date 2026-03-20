---
type: lesson
title: Testing Policies
focus: /workspace/test/policies/ticket_policy_test.rb
custom:
  shell:
    workdir: "/workspace"
---

Testing Policies
-----------------

With authorization logic extracted into policy classes, we can now test it at two levels:

1. **Policy unit tests** — test each rule directly against the policy class
2. **Integration tests** — verify that the correct policy rule is invoked for each controller action

This separation means policy tests cover every role/permission combination, while integration tests just confirm the wiring — no need to repeat role checks in both places.

### Step 1: Test helper setup

Open `test/test_helper.rb` — we've already added the Action Policy test helper for you:

```ruby title="test/test_helper.rb" add={2,9}
require "rails/test_help"
require "action_policy/test_helper"

# ...

class ActionDispatch::IntegrationTest
  # ...

  include ActionPolicy::TestHelper
end
```

This gives integration tests access to `assert_authorized_to` — which we'll use in Step 3.

### Step 2: Write policy unit tests

Policy tests are plain Ruby—instantiate the policy with a record and context, then call `.apply(:rule?)`.

Open `test/policies/ticket_policy_test.rb` and add a couple of tests:

```ruby title="test/policies/ticket_policy_test.rb"
require "test_helper"

class TicketPolicyTest < ActiveSupport::TestCase
  test "manage? allows ticket owner" do
    policy = TicketPolicy.new(tickets(:password_reset), user: users(:alice))
    assert policy.apply(:manage?)
  end

  test "manage? denies unassigned agent" do
    policy = TicketPolicy.new(tickets(:password_reset), user: users(:bob))
    assert_not policy.apply(:manage?)
  end
end
```

The pattern is straightforward:
- `TicketPolicy.new(record, user: user)` — create a policy instance
- `policy.apply(:rule?)` — evaluate the rule (returns `true` or `false`)

Now add a test for `CommentPolicy` in `test/policies/comment_policy_test.rb`:

```ruby title="test/policies/comment_policy_test.rb"
require "test_helper"

class CommentPolicyTest < ActiveSupport::TestCase
  test "destroy? allows comment author" do
    comment = comments(:alice_on_password_reset)
    policy = CommentPolicy.new(comment, user: users(:alice))
    assert policy.apply(:destroy?)
  end
end
```

Run the policy tests:

```bash
$ bin/rails test test/policies
```

:::tip
Click **Solve** to see the complete test suite covering all roles and rules for both policies.
:::

### Step 3: Simplify integration tests

Now that policy logic is tested in isolation, integration tests don't need to re-check every role combination. Instead, use `assert_authorized_to` to verify that the **correct rule is called** for each action.

Open `test/integration/tickets_test.rb` and replace the authorization-specific tests. For example, instead of these six tests checking different roles for edit/update/destroy:

```ruby
test "owner can edit their ticket" do ...
test "assigned agent can edit the ticket" do ...
test "agent cannot edit a ticket not assigned to them" do ...
test "admin can edit any ticket" do ...
test "owner cannot delete their ticket" do ...
test "admin can delete a ticket" do ...
```

You can write one `assert_authorized_to` per action:

```ruby title="test/integration/tickets_test.rb" ins={10} del={6-9} {26,42,49,56}
require "test_helper"

class TicketsTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @alices_ticket = tickets(:password_reset)
    @bobs_assigned_ticket = tickets(:billing)
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
```

`assert_authorized_to` wraps a block and verifies that `authorize!` was called with the expected rule, target, and policy — regardless of whether the authorization succeeded or failed. The actual "who can do what" logic is already covered by your policy tests.

:::info
The rule passed to the `assert_authorized_to` helper is the actual policy rule applied, not an alias used in a controller. We do not assert authorization arguments but the actual logic. That's why we have `manage?`, not `update?` or `edit?`.
:::

Now simplify `test/integration/comments_test.rb` the same way:

```ruby title="test/integration/comments_test.rb" del={6,7,9} ins={10} {23}
require "test_helper"

class CommentsTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @ticket = tickets(:password_reset)
    @alices_comment = comments(:alice_on_password_reset)
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
```

### Verify everything passes

Run the full test suite:

```bash
$ bin/rails test
```

### What changed

| Before | After |
|---|---|
| 16 integration tests checking every role/action combination | 9 integration tests verifying wiring + 3 policy unit tests |
| Authorization logic tested only through HTTP round-trips | Policy rules tested directly as Ruby objects |
| Adding a new role means updating many integration tests | Adding a new role means adding one policy test |
