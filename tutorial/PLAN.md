# Tutorial: Getting Started with Action Policy on Rails

## Context

Create a progressive tutorial demonstrating how Action Policy helps manage evolving authorization requirements in a Rails app. The tutorial starts with no authorization, shows the pain of ad-hoc checks, then introduces Action Policy features incrementally as new "requirements" appear.

## Domain: Help Desk / Support Ticket System

**Models:**

```ruby
User    (name, email, role: string [customer, agent, admin], level: integer [1-3, for agents])
Ticket  (title, description, status: string [open, in_progress, resolved, closed],
         escalation_level: integer [1-3, default: 1], user_id, agent_id)
Comment (body, ticket_id, user_id, internal: boolean)
```

**Why this domain:**
- Three natural roles with distinct permissions (customer, agent, admin)
- Ownership (customers own tickets, users own comments)
- Assignment (agent assigned to ticket)
- Visibility rules (internal comments hidden from customers)
- Status transitions restricted by role
- Rich scoping story (my tickets vs assigned vs all)
- Escalation levels create natural "can see but can't act" scenarios for failure reasons

**UI:** Pure ERB, scaffold-style. Minimal styling. No JavaScript.

---

## Chapter Outline (7 chapters)

### Chapter 1: "The Starting Point"

**State:** A working Rails app with basic auth and CRUD. No authorization.

- User model with `has_secure_password` (or simple session-based auth stub)
- Ticket scaffold: index, show, new, create, edit, update
- Comment as nested resource under Ticket (just create + show inline)
- Everyone can see everything, edit everything, delete everything

**What we show:** The app works but has no access control at all.

---

### Chapter 2: "Ad-hoc Authorization"

**New requirements arrive:**
1. Customers can only edit their own tickets
2. Only agents can change ticket status
3. Only the comment author can delete their comment

**Implementation:** Inline `before_action` checks and view conditionals:

```ruby
# tickets_controller.rb
before_action :require_owner, only: [:edit, :update]

def require_owner
  redirect_to tickets_path, alert: "Not authorized" unless @ticket.user == current_user
end
```

```erb
<%# views — duplicated logic %>
<% if ticket.user == current_user %>
  <%= link_to "Edit", edit_ticket_path(ticket) %>
<% end %>
```

**Then MORE requirements:**
- Agents should also be able to edit tickets assigned to them
- Admins can do everything

**The pain:** Checks multiply and scatter across controllers and views:
```ruby
unless @ticket.user == current_user ||
       (current_user.agent? && @ticket.agent == current_user) ||
       current_user.admin?
```

**Takeaway:** Logic is duplicated, untestable, and increasingly fragile.

---

### Chapter 3: "Enter Action Policy"

**Install** `action_policy` gem. Run generator.

**Create policies:**

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy < ActionPolicy::Base
end

# app/policies/ticket_policy.rb
class TicketPolicy < ApplicationPolicy
  def show?
    user.admin? || user.agent? || record.user_id == user.id
  end

  def update?
    user.admin? || record.user_id == user.id ||
      (user.agent? && record.agent_id == user.id)
  end

  def destroy?
    user.admin?
  end
end
```

**Refactor controllers:**
```ruby
def update
  @ticket = Ticket.find(params[:id])
  authorize! @ticket
  # ...
end
```

**Refactor views:**
```erb
<% if allowed_to?(:update?, ticket) %>
  <%= link_to "Edit", edit_ticket_path(ticket) %>
<% end %>
```

**Key concepts:**
- `ApplicationPolicy` base class
- Rule methods returning true/false
- `authorize!` in controllers (raises `ActionPolicy::Unauthorized`)
- `allowed_to?` in views
- Automatic policy lookup (Ticket → TicketPolicy)
- Automatic rule inference (edit action → edit? rule, which falls back to update? via default alias)

---

### Chapter 4: "Evolving Requirements" — Pre-checks & Aliases

**New requirement:** Admins bypass all authorization checks across the entire app.

**Introduce pre-checks in ApplicationPolicy:**
```ruby
class ApplicationPolicy < ActionPolicy::Base
  pre_check :allow_admins

  private

  def allow_admins
    allow! if user.admin?
  end
end
```

Remove all `user.admin?` checks from individual rules — handled globally now.

**Simplify with aliases:**
```ruby
class TicketPolicy < ApplicationPolicy
  alias_rule :show?, :update?, :destroy?, to: :manage?

  def manage?
    record.user_id == user.id ||
      (user.agent? && record.agent_id == user.id)
  end
end
```

**Introduce CommentPolicy with internal comments rule:**
```ruby
class CommentPolicy < ApplicationPolicy
  def show?
    !record.internal? || user.agent?
  end

  def create?
    allowed_to?(:show?, record.ticket)
  end

  def destroy?
    record.user_id == user.id
  end
end
```

**Key concepts:**
- Pre-checks for cross-cutting concerns
- `allow!` for fail-fast authorization
- `alias_rule` to reduce duplication
- `allowed_to?` to delegate to another policy (CommentPolicy → TicketPolicy)

---

### Chapter 5: "Scoping" — Filtering what users see

**New requirement:**
- Customers see only their own tickets on the index page
- Agents see tickets assigned to them + unassigned tickets
- Admins see everything
- Internal comments are hidden from customers in ticket show view

**Introduce relation scoping:**
```ruby
class TicketPolicy < ApplicationPolicy
  relation_scope do |relation|
    if user.agent?
      relation.where(agent_id: [user.id, nil])
    else
      relation.where(user_id: user.id)
    end
  end
end

class CommentPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if user.agent?
    relation.where(internal: false)
  end
end
```

**Controller:**
```ruby
def index
  @tickets = authorized_scope(Ticket.all)
end

def show
  @ticket = Ticket.find(params[:id])
  authorize! @ticket
  @comments = authorized_scope(@ticket.comments)
end
```

**Add safety nets:**
```ruby
class ApplicationController < ActionController::Base
  verify_authorized
end

class TicketsController < ApplicationController
  verify_authorized_scoped only: :index
end
```

**Key concepts:**
- `relation_scope` for ActiveRecord filtering
- `authorized_scope` in controllers
- Pre-check in admin means scoping returns all (admin bypasses)
- `verify_authorized` / `verify_authorized_scoped` as safety nets
- Scoping comments to hide internal ones from customers

---

### Chapter 6: "Testing Policies"

**Write policy specs using Action Policy's RSpec DSL:**

```ruby
# spec/policies/ticket_policy_spec.rb
describe TicketPolicy do
  let(:user) { build_stubbed(:user, role: "customer") }
  let(:record) { build_stubbed(:ticket) }
  let(:context) { {user: user} }

  describe_rule :manage? do
    failed "when user is a random customer"

    succeed "when user is the ticket creator" do
      let(:record) { build_stubbed(:ticket, user: user) }
    end

    context "when user is an agent" do
      let(:user) { build_stubbed(:user, role: "agent") }

      succeed "when assigned to the ticket" do
        let(:record) { build_stubbed(:ticket, agent: user) }
      end

      failed "when not assigned"
    end

    succeed "when user is admin" do
      let(:user) { build_stubbed(:user, role: "admin") }
    end
  end
end
```

**Test authorization in controllers:**
```ruby
# Check that authorize! is called
it "authorizes the ticket" do
  expect { patch :update, params: {id: ticket.id, ticket: {title: "new"}} }
    .to be_authorized_to(:update?, ticket)
end
```

**Test scoping:**
```ruby
it "scopes tickets for customers" do
  expect { get :index }
    .to have_authorized_scope(:relation)
    .with(TicketPolicy)
end
```

**Key concepts:**
- `describe_rule` / `succeed` / `failed` DSL
- Testing pre-checks (admin case)
- `be_authorized_to` matcher for controller tests
- `have_authorized_scope` matcher

---

### Chapter 7: "Why Can't I Do This?" — Failure Reasons, Details & i18n

**New requirement:** Support ticket escalation. Tickets have an `escalation_level` (1–3). Agents have a `level` (1–3). An agent can only comment on or resolve a ticket if their level is >= the ticket's escalation level. However, all agents can still **see** all tickets — they just can't **act** on high-level ones. When they can't, the UI should show disabled buttons with a tooltip explaining *why*.

**Add migration:** `escalation_level` to Ticket (default: 1), `level` to User (default: 1).

**Update TicketPolicy with failure reasons:**
```ruby
class TicketPolicy < ApplicationPolicy
  def resolve?
    allowed_to?(:sufficient_level?)
  end

  def sufficient_level?
    deny!(:insufficient_level) if user.level < record.escalation_level

    true
  end
end
```

**Update CommentPolicy:**
```ruby
class CommentPolicy < ApplicationPolicy
  def create?
    allowed_to?(:show?, record.ticket) &&
      allowed_to?(:sufficient_level?, record.ticket, with: TicketPolicy)
  end
end
```

When a level-1 agent tries to comment on a level-3 ticket, the failure reasons will capture exactly why:
```ruby
ex.result.reasons.to_h #=> { ticket: [:sufficient_level?] }
```

**Add details for richer messages:**
```ruby
def sufficient_level?
  if user.level < record.escalation_level
    details[:required_level] = record.escalation_level
    details[:current_level] = user.level
    deny!(:insufficient_level)
  end

  true
end
```

**Add i18n translations:**
```yaml
en:
  action_policy:
    policy:
      ticket:
        manage?: "You don't have access to this ticket"
        sufficient_level?: "This ticket requires level %{required_level} clearance (you are level %{current_level})"
      comment:
        create?: "You cannot comment on this ticket"
        show?: "This comment is for internal use only"
```

**Show in views — disabled button with tooltip:**
```erb
<% result = allowance_to(:resolve?, ticket) %>
<% if result.value %>
  <%= button_to "Resolve", resolve_ticket_path(ticket) %>
<% else %>
  <button disabled title="<%= result.message %>">Resolve</button>
<% end %>
```

**Handle globally in ApplicationController:**
```ruby
rescue_from ActionPolicy::Unauthorized do |ex|
  redirect_back fallback_location: root_path, alert: ex.result.message
end
```

**Key concepts:**
- `deny!(:reason)` to set explicit failure reasons
- `details[:key]` for additional context in error messages
- `ex.result.reasons.to_h` for programmatic access to failure reasons
- `allowance_to` to get the result object (not just true/false) for UI rendering
- i18n with interpolation from details
- Disabled UI elements with actionable explanations

---

## Features Covered (in order)

1. Basic policies and rule methods
2. `authorize!` and `allowed_to?`
3. Automatic policy/rule lookup and inference
4. Pre-checks with `allow!`
5. `alias_rule` for deduplication
6. Cross-policy delegation with `allowed_to?(:rule?, other_record)`
7. `relation_scope` and `authorized_scope`
8. `verify_authorized` / `verify_authorized_scoped` safety nets
9. RSpec testing DSL
10. Failure reasons with `deny!(:reason)` and `details`
11. `allowance_to` for UI-level permission checks
12. i18n with interpolation for actionable error messages

## Features Intentionally Omitted

- Extended authorization context (beyond default `user`)
- Caching
- Namespaces
- GraphQL integration
- Custom lookup chain
- Debugging (`pp`)
- Instrumentation

## Verification

- Each chapter represents a working app state
- `rails test` / `rspec` passes at each stage
- Manual testing: log in as customer/agent/admin, verify access rules
