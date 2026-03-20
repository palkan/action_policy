---
type: lesson
title: Enter Action Policy
focus: /workspace/app/controllers/tickets_controller.rb
custom:
  shell:
    workdir: "/workspace"
---

Enter Action Policy
-------------------

In the previous lesson, you added authorization checks directly in controllers. It works, but the logic is scattered and duplicated. Let's extract it into dedicated **policy classes** using [Action Policy](https://actionpolicy.evilmartians.io).

A policy class is a plain Ruby class that encapsulates authorization rules for a specific resource. Instead of `before_action` callbacks with inline conditions, you write predicate methods like `update?` and `destroy?` that return `true` or `false`.

### Step 1: Generate policy files

Action Policy includes Rails generators. Run them to scaffold the base class and resource policies:

```bash
$ bin/rails g action_policy:install
```

This creates `app/policies/application_policy.rb` — the base class that all policies inherit from.

Now generate policies for Ticket and Comment:

```bash
$ bin/rails g action_policy:policy Ticket
$ bin/rails g action_policy:policy Comment
```

Each generator creates a policy file in `app/policies/` (and a test file you can ignore for now).

### Step 2: Configure ApplicationController

Action Policy needs to know how to find the current user. Since our app uses `Current.user` (not `current_user`), we must tell Action Policy where to find it. We also need to handle authorization failures gracefully.

Open `app/controllers/application_controller.rb` and add:

```ruby title="app/controllers/application_controller.rb" add={4,6-8}
class ApplicationController < ActionController::Base
  include Authentication

  authorize :user, through: -> { Current.user }

  rescue_from ActionPolicy::Unauthorized do
    redirect_back fallback_location: root_path, alert: "Not authorized"
  end
end
```

- `authorize :user` tells Action Policy to pass `Current.user` as the `user` context to every policy
- `rescue_from` catches `ActionPolicy::Unauthorized` exceptions (raised by `authorize!`) and redirects with a flash message — matching our existing test expectations

### Step 3: Write TicketPolicy rules

Open `app/policies/ticket_policy.rb` and define the authorization rules:

```ruby title="app/policies/ticket_policy.rb"
class TicketPolicy < ApplicationPolicy
  def show?
    true
  end

  def manage?
    record.user_id == user.id ||
      (user.agent? && record.agent_id == user.id) ||
      user.admin?
  end

  def destroy?
    user.admin?
  end
end
```

Inside a policy, `user` is the current user (from the authorization context) and `record` is the object being authorized (e.g., a `Ticket` instance).

Notice the `manage?` rule—it's a default rule used for all actions, it's used when there is no explicit rule defined in the base or resource-specific policy class. For example, in our case the `manage?` rule will be used when we ask for the `update?` or `edit?` permission but not `destroy?`.

### Step 4: Refactor TicketsController

Now replace the ad-hoc callbacks with a single `authorize!` call. The cleanest place is inside `set_ticket` — since every action that loads a ticket should also authorize it:

```ruby title="app/controllers/tickets_controller.rb" del={3,4,55-68} add={49}
class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show edit update destroy]
  before_action :require_owner_or_assigned_agent, only: %i[edit update]
  before_action :require_admin, only: %i[destroy]

  def index
    @tickets = Ticket.includes(:user, :agent).order(created_at: :desc)
  end

  def show
    @comments = @ticket.comments.includes(:user).order(:created_at)
    @comment = Comment.new
  end

  def new
    @ticket = Ticket.new
  end

  def create
    @ticket = Current.user.tickets.build(ticket_params)

    if @ticket.save
      redirect_to @ticket, notice: "Ticket created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ticket.update(ticket_params)
      redirect_to @ticket, notice: "Ticket updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ticket.destroy
    redirect_to tickets_path, notice: "Ticket deleted."
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
    authorize! @ticket
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :escalation_level, :agent_id)
  end
  
  def require_owner_or_assigned_agent
    unless @ticket.user == Current.user ||
            (Current.user.agent? && @ticket.agent == Current.user) ||
            Current.user.admin?
      redirect_to tickets_path, alert: "Not authorized"
    end
  end

  def require_admin
    unless Current.user.admin?
      redirect_to tickets_path, alert: "Not authorized"
    end
  end
end
```

When `authorize!` is called, Action Policy:
1. Infers the policy class from the record: `Ticket` -> `TicketPolicy`
2. Infers the rule from the controller action: `edit` -> `edit?` (which falls back to `manage?`)
3. Evaluates the rule — if it returns `false`, raises `ActionPolicy::Unauthorized`

The `require_owner_or_assigned_agent` and `require_admin` methods are gone. All that logic now lives in `TicketPolicy`.

Run the ticket tests to verify:

```bash
$ bin/rails test test/integration/tickets_test.rb
```

You should see some failures due to redirects mismatch:

```bash
Failure:
TicketsTest#test_owner_cannot_delete_their_ticket [test/integration/tickets_test.rb:86]:
Expected response to be a redirect to <http://www.example.com/tickets> but was a redirect to <http://www.example.com/>.
Expected "http://www.example.com/tickets" to be === "http://www.example.com/".
```

That happened because we now a single place where we redirect unauthorized requests from—the `rescue_from` handler in the `app/controllers/application_controller.rb`. We can update it as follows to preserve the previous behavior:

```ruby title="app/controllers/application_controller.rb" ins={10-12} {7}
class ApplicationController < ActionController::Base
  include Authentication

  authorize :user, through: -> { Current.user }

  rescue_from ActionPolicy::Unauthorized do
    redirect_back fallback_location: unauhorized_redirect_path, alert: "Not authorized"
  end
  
  private
  
  def unauthorized_redirect_path = root_path
end
```

Now, add the following to the `app/controllers/application_controller.rb`:

```ruby
def unauthorized_redirect_path = tickets_path
```

Run tests again—all should be green!

### Step 5: Write CommentPolicy rules

Open `app/policies/comment_policy.rb`:

```ruby title="app/policies/comment_policy.rb"
class CommentPolicy < ApplicationPolicy
  def destroy?
    record.user_id == user.id || user.admin?
  end
end
```

### Step 6: Refactor CommentsController

Add `authorize!` to the `set_comment` callback and remove the ad-hoc `require_author_or_admin` method:

```ruby title="app/controllers/comments_controller.rb" del={4,36-41} add={30,43}
class CommentsController < ApplicationController
  before_action :set_ticket
  before_action :set_comment, only: %i[destroy]
  before_action :require_author_or_admin, only: %i[destroy]

  def create
    @comment = @ticket.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to @ticket, notice: "Comment added."
    else
      redirect_to @ticket, alert: "Comment can't be blank."
    end
  end

  def destroy
    @comment.destroy
    redirect_to @ticket, notice: "Comment deleted."
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def set_comment
    @comment = @ticket.comments.find(params[:id])
    authorize! @comment
  end

  def comment_params
    params.require(:comment).permit(:body, :internal)
  end
  
  def require_author_or_admin
    unless @comment.user == Current.user || Current.user.admin?
      redirect_to @ticket, alert: "Not authorized"
    end
  end
  
  def unauthorized_redirect_path = ticket_path(@ticket)
end
```

### Verify everything passes

Run the full test suite:

```bash
$ bin/rails test
```

All tests should pass — the behavior is identical, but the authorization logic is now centralized in policy classes instead of scattered across controllers.

### What changed

Compare what you had before and after:

| Before (ad-hoc) | After (Action Policy) |
|---|---|
| `require_owner_or_assigned_agent` in controller | `TicketPolicy#update?` |
| `require_admin` in controller | `TicketPolicy#destroy?` |
| `require_author_or_admin` in controller | `CommentPolicy#destroy?` |
| Logic duplicated across controllers and views | Single source of truth in policy classes |
| Hard to test authorization in isolation | Policies are plain Ruby classes — easy to unit test |
