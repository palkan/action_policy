---
type: lesson
title: Ad-hoc Authorization
focus: /workspace/test/integration/tickets_test.rb
custom:
  shell:
    workdir: "/workspace"
---

Ad-hoc Authorization
--------------------

Let's fix the "everyone can do everything" problem and implement the following access control requirements:

1. Only the **ticket owner**, the **assigned agent**, or an **admin** can edit a ticket
2. Only an **admin** can delete a ticket
3. Only the **comment author** or an **admin** can delete a comment

Let's implement these rules using plain Rails — `before_action` callbacks with conditional checks.

### Start with failing tests

We've already written integration tests that encode these rules. Open `test/integration/tickets_test.rb` in the editor (it should be focused already) and look through the authorization tests.

Run the test suite to see what fails:

```bash
$ bin/rails test
```

You should see **4 failures** — the tests that expect unauthorized users to be _denied_ access. Everything else passes because there are no restrictions yet.

### Step 1: Restrict ticket editing

Open `app/controllers/tickets_controller.rb`. Add a `before_action` that checks whether the current user is allowed to edit the ticket. The check should run after `set_ticket` (which loads `@ticket`):

```ruby title="app/controllers/tickets_controller.rb" add={3} ins={3}
class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show edit update destroy]
  before_action :require_owner_or_assigned_agent, only: %i[edit update]
```

Then add the private method at the bottom of the controller:

```ruby title="app/controllers/tickets_controller.rb"
def require_owner_or_assigned_agent
  unless @ticket.user == Current.user ||
         (Current.user.agent? && @ticket.agent == Current.user) ||
         Current.user.admin?
    redirect_to tickets_path, alert: "Not authorized"
  end
end
```

The condition allows access if the user is the ticket owner **or** an agent assigned to this ticket **or** an admin.

### Step 2: Restrict ticket deletion

Add another `before_action` for the `destroy` action — only admins should be able to delete tickets:

```ruby title="app/controllers/tickets_controller.rb" add={4} ins={4}
class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show edit update destroy]
  before_action :require_owner_or_assigned_agent, only: %i[edit update]
  before_action :require_admin, only: %i[destroy]
```

```ruby title="app/controllers/tickets_controller.rb"
def require_admin
  unless Current.user.admin?
    redirect_to tickets_path, alert: "Not authorized"
  end
end
```

Run the ticket tests to check your progress:

```bash
$ bin/rails test test/integration/tickets_test.rb
```

All ticket tests should pass now.

### Step 3: Restrict comment deletion

Open `app/controllers/comments_controller.rb`. Define a `before_action` callback for the `destroy` action to perform an authorization check:

```ruby title="app/controllers/comments_controller.rb" add={4}
class CommentsController < ApplicationController
  before_action :set_ticket
  before_action :set_comment, only: %i[destroy]
  before_action :require_author_or_admin, only: %i[destroy]
```

Add the private method:

```ruby title="app/controllers/comments_controller.rb"
def require_author_or_admin
  unless @comment.user == Current.user || Current.user.admin?
    redirect_to @ticket, alert: "Not authorized"
  end
end
```

### Verify everything passes

Run the full test suite:

```bash
$ bin/rails test
```

All tests should be green now.

### The problem with this approach

Take a look at what you just wrote. The authorization logic is:

- **Scattered** across two controllers (and will spread to views next)
- **Duplicated** — the "admin can do anything" check appears in every method
- **Hard to test in isolation** — you can only test authorization through full integration tests
- **Fragile** — adding a new role or rule means hunting through every controller

This is exactly the kind of complexity that **Action Policy** is designed to solve. In the next lessons, we'll extract these checks into dedicated _policy classes_ that are easy to read, test, and maintain.
