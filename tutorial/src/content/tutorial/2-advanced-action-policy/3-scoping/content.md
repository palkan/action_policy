---
type: lesson
title: Scoping
focus: /workspace/app/policies/ticket_policy.rb
previews:
  - 3000
custom:
  shell:
    workdir: "/workspace"
---

Scoping
-------

So far, we've been authorizing access to **individual records**—can this user view this ticket? Can they edit it? But there's a different question we haven't addressed: **which records should a user see in the first place?**

Right now, the tickets index page shows _every_ ticket to _every_ user. A customer sees tickets created by other customers (go to [/tickets](http://localhost:3000/tickets) and check yourself). An agent sees tickets they have nothing to do with. That's not how a real help desk works.

:::tip
If you don't see tickets from other customers but Alice, run `bin/rails db:seed` to re-populate the tutorial's data.
:::

We also have a visibility problem with comments: Bob's internal note on the billing ticket—"Confirmed duplicate charge. Refund initiated."—is visible to Alice (a customer). Internal comments should be hidden from customers entirely.

Action Policy solves this with **scoping**—defining how to filter collections based on the current user.

### Step 1: Add a relation scope to TicketPolicy

Open `app/policies/ticket_policy.rb`. Add a `relation_scope` block at the top of the class, before the rule methods:

```ruby title="app/policies/ticket_policy.rb" ins={2-8}
class TicketPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if user.admin?
    next relation.where(agent_id: [user.id, nil]) if user.agent?

    relation.where(user_id: user.id)
  end

  def show?
    true
  end

  def manage?
    record.user_id == user.id ||
      (user.agent? && record.agent_id == user.id)
  end

  def destroy? = false
end
```

`relation_scope` defines how to filter an ActiveRecord relation for the current user:

- **Customers** see only their own tickets (`where(user_id: user.id)`)
- **Agents** see tickets assigned to them _plus_ unassigned tickets (`where(agent_id: [user.id, nil])`)
- **Admins** see everything

:::info
`next relation` is a Ruby pattern for returning a value from a block early. It's equivalent to `return relation` in a regular method—agents see all comments, no filtering needed.
:::

### Step 2: Use authorized_scope in the controller

Open `app/controllers/tickets_controller.rb`. Update the `index` action to use `authorized_scope`:

```ruby title="app/controllers/tickets_controller.rb" del={2} ins={3}
  def index
    @tickets = Ticket.includes(:user, :agent).order(created_at: :desc)
    @tickets = authorized_scope(Ticket.all).includes(:user, :agent).order(created_at: :desc)
  end
```

`authorized_scope(Ticket.all)` looks up `TicketPolicy`, finds its `relation_scope`, and applies it to the given relation. The result is a filtered query—only the tickets the current user is allowed to see.

### Step 3: Scope comments to hide internal notes

Now let's fix the internal comments problem. Open `app/policies/comment_policy.rb` and add both a `relation_scope` and a `show?` rule:

```ruby title="app/policies/comment_policy.rb" ins={4-7,9-11}
class CommentPolicy < ApplicationPolicy
  authorize :ticket, optional: true

  relation_scope do |relation|
    next relation unless user.customer?

    relation.where(internal: false)
  end

  def show?
    !record.internal? || user.agent?
  end

  def create?
    user.agent? || ticket&.open? || ticket&.in_progress?
  end

  def destroy?
    record.user_id == user.id
  end
end
```

Two layers of protection here:

- `relation_scope` filters at the **query level**—internal comments are excluded from the SQL query for customers, so they never reach the view
- `show?` provides **direct-access protection**—if someone tries to access an internal comment directly (e.g., via a future API), the rule blocks it

### Step 4: Scope comments in the controller

Update the `show` action in `app/controllers/tickets_controller.rb` to scope comments:

```ruby title="app/controllers/tickets_controller.rb" del={2} ins={3}
  def show
    @comments = @ticket.comments.includes(:user).order(:created_at)
    @comments = authorized_scope(@ticket.comments).includes(:user).order(:created_at)
    @comment = Comment.new
  end
```

`authorized_scope(@ticket.comments)` applies `CommentPolicy`'s `relation_scope` to the ticket's comments association. For customers, internal comments are filtered out before they ever reach the template.

### Try it out

Go to the [Tickets page](http://localhost:3000/tickets). You're logged in as **Alice** (a customer)—you should see only her three tickets. Dana's and Eve's tickets are not visible.

Now open the [Billing ticket](http://localhost:3000/tickets/2). Bob's internal comment ("Confirmed duplicate charge. Refund initiated.") should be **hidden**.

Sign in as **Bob** (agent) and check the tickets index—you should see more tickets (assigned to Bob plus unassigned ones). Open the billing ticket and the internal comment should be **visible**.

### Verify with tests

Run the tests:

```bash
$ bin/rails test
```

:::tip
Click **Solve** to see the complete code including updated tests for scoping and comment visibility.
:::

### What changed

| Concept | What it does |
|---|---|
| `relation_scope { \|relation\| ... }` | Defines how to filter ActiveRecord relations per user |
| `authorized_scope(relation)` | Applies the matching scope in the controller |
| `show?` on CommentPolicy | Direct-access protection for internal comments |
| Pre-check + scoping | Admin pre-check means scoping is skipped—admins see everything |
