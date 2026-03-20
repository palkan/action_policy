---
type: lesson
title: Authorization Context
focus: /workspace/app/policies/comment_policy.rb
previews:
  - 3000
custom:
  shell:
    workdir: "/workspace"
---

Authorization Context
----------------------

Right now, `CommentPolicy` only has a `destroy?` rule. But we also need to control who can **create** comments. Here's a new requirement: customers shouldn't be able to comment on resolved tickets—only agents should.

The `create?` rule needs access to the comment's **ticket**—not just the comment itself. And since we're authorizing _before_ the comment is persisted, there's no `record` to work with yet. Action Policy solves this with **authorization context**—additional objects you declare alongside the default `user`.

:::info
No one stops you from using `ticket.comments.build` (non-persisted) as authorization target for the `create` action—it will work. However, we believe that using non-persisted (and, thus, non-existent) records is a design smell ("one cannot simply authorize access to nothing") and recommend using authorization context instead.
:::

### Step 1: Add create? with ticket context

Open `app/policies/comment_policy.rb`. We need two changes: declare `ticket` as authorization context, and add the `create?` rule that uses it:

```ruby title="app/policies/comment_policy.rb" ins={2,4-7}
class CommentPolicy < ApplicationPolicy
  authorize :ticket, optional: true

  def create?
    user.agent? || ticket&.open? || ticket&.in_progress?
  end

  def destroy?
    record.user_id == user.id
  end
end
```

Three things to unpack here:

- `authorize :ticket, optional: true` declares that this policy can receive a `ticket` object as authorization context. The `optional: true` flag means it won't raise when `ticket` is absent—which is the case for rules like `destroy?` that don't need it.
- Agents can always comment (and admins are handled by the pre-check), but customers can only comment on open or in-progress tickets—not resolved or closed ones.

### Step 2: Provide ticket context in the controller

The controller needs to tell Action Policy where to find the `ticket` context. Open `app/controllers/comments_controller.rb` and add the context declaration and the `authorize!` call:

```ruby title="app/controllers/comments_controller.rb" ins={4-5,8}
class CommentsController < ApplicationController
  before_action :set_ticket
  before_action :set_comment, only: %i[destroy]

  authorize :ticket, through: -> { @ticket }

  def create
    authorize!
    @comment = @ticket.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to @ticket, notice: "Comment added."
    else
      redirect_to @ticket, alert: "Comment can't be blank."
    end
  end

  # ...
```

- `authorize :ticket, through: -> { @ticket }` tells Action Policy to pass `@ticket` as the `ticket` context to any policy used within the current execution context
- `authorize!` with no arguments infers everything from the controller: `CommentsController` → `Comment` (the authorization target), `create` action → `create?` (the rule), and `CommentPolicy` (the policy class)

### Step 3: Conditionally show the comment form

Open `app/views/tickets/show.html.erb`. Wrap the comment form with a `create?` check:

```erb title="app/views/tickets/show.html.erb" {1}
<% if allowed_to?(:create?, Comment, context: {ticket: @ticket}) %>
  <div class="card mt-md">
    <div class="card__header">
      <h3>Add a comment</h3>
    </div>
    <div class="card__body">
      <%= render "comments/form", ticket: @ticket, comment: Comment.new %>
    </div>
  </div>
<% end %>
```

`allowed_to?(:create?, Comment, context: {ticket: @ticket})` passes the `Comment` class to Action Policy, which looks up `CommentPolicy` and evaluates `create?`. The `ticket` context here must be specified explicitly, since TicketsController doesn't define it as the authorization context via the `authorize :ticket` declaration.

### Try it out

Go to the [Tickets page](http://localhost:3000/tickets) (you're logged in as **Alice**) and open any resolved ticket—the comment form should be **hidden**.

Now try to open an open ticket—the form should appear.

Sign in as **Bob** (agent) and open the resolved ticket—the form should be **visible** (agents can always comment).

### Verify with tests

Run the tests:

```bash
$ bin/rails test
```

:::tip
Click **Solve** to see the complete code including updated tests for the new `CommentPolicy` rules.
:::

### What changed

| Concept | What it does |
|---|---|
| `authorize :ticket, optional: true` | Declares additional authorization context in a policy |
| `authorize :ticket, through: -> { @ticket }` in controller | Provides the context value to policies |
| `authorize!` (no args) | Infers record, rule, and policy from the controller |
