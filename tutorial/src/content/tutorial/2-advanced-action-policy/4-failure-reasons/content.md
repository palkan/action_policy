---
type: lesson
title: Failure Reasons
focus: /workspace/app/policies/ticket_policy.rb
previews:
  - 3000
custom:
  shell:
    workdir: "/workspace"
---

Failure Reasons
---------------

So far, when authorization fails, the user sees a generic "Not authorized" flash message. That's not very helpful—*why* can't they do this? Action Policy can tell users exactly what went wrong, using **failure reasons** and **i18n support**.

To demonstrate this, we'll add a "Resolve" button to tickets. The rule: only agents can resolve tickets, and only if their clearance level is high enough. The billing ticket has escalation level 3, but Bob (an agent) is only level 2—so he can see and edit the ticket, but can't resolve it.

We've already add the corresponding action to `app/controllers/tickets_controller.rb`, route to `config/routes.rb`, and added the "Resolve" button to the `app/views/tickets/show.html.erb` template (but no `allowed_to?` check yet). The new policy rule in `app/policies/ticket_policy.rb` for now just checks that the current user is an agent:

```ruby title="app/policies/ticket_policy.rb" ins={3-5}
  def destroy? = false

  def resolve?
    user.agent?
  end
```

### Try it out

Open a ticket as **Bob** (agent)—the Resolve button appears. Click it on the [password reset ticket](http://localhost:3000/tickets/1)—it works, the ticket is resolved.

Now sign in as **Alice** (customer) and open a ticket. The Resolve button is visible—Alice shouldn't see it, but let's first focus on the error message. Click it. You'll see a flash: **"Not authorized"**. That's the generic message from `ApplicationController`'s `rescue_from`. Not very informative.

### Step 1: Replace the static message with i18n

Let's use Action Policy's built-in i18n support. First, update `app/controllers/application_controller.rb` to use `ex.result.message` instead of a hardcoded string:

```ruby title="app/controllers/application_controller.rb" del={2} ins={3}
  rescue_from ActionPolicy::Unauthorized do |ex|
    redirect_back fallback_location: unauthorized_redirect_path, alert: "Not authorized"
    redirect_back fallback_location: unauthorized_redirect_path, alert: ex.result.message
  end
```

Then create `config/locales/action_policy.en.yml` with a default message:

```yaml title="config/locales/action_policy.en.yml"
en:
  action_policy:
    unauthorized: "Sorry, you are not allowed to perform this action"
```

Now try clicking Resolve as Alice again—the flash says **"Sorry, you are not allowed to perform this action"**. Better, but still generic. It's the same message for every denied action.

### Step 2: Add a rule-specific message

Action Policy looks up i18n keys in a specific order: first the rule-specific key, then the default. Add a key for `resolve?`:

```yaml title="config/locales/action_policy.en.yml" ins={4-6}
en:
  action_policy:
    unauthorized: "Sorry, you are not allowed to perform this action"
    policy:
      ticket:
        resolve?: "You are not allowed to resolve this ticket"
```

Try again as Alice—now the flash says **"You are not allowed to resolve this ticket"**. More helpful! But still the same message whether you're a customer (who can never resolve) or an agent with insufficient level. We can do better.

### Step 3: Introduce check?-based reasons

Refactor `resolve?` to use `check?` so Action Policy can track *which specific check* failed:

```ruby title="app/policies/ticket_policy.rb" del={1-3} ins={5-19}
  def resolve?
    user.agent?
  end

  def resolve?
    check?(:agent_role?) && check?(:sufficient_level?)
  end

  def agent_role?
    user.agent?
  end

  def sufficient_level?
    return true unless record.is_a?(Ticket)

    user.level >= record.escalation_level
  end
```

`check?` delegates to a sub-rule and records which one fails. If `agent_role?` returns false, Action Policy records `:agent_role?` as the failure reason. If `sufficient_level?` fails, it records `:sufficient_level?`.

The guard `return true unless record.is_a?(Ticket)` lets the rule work with both ticket instances and the `Ticket` class—we'll need this for the view in the next step.

Now update the i18n to provide per-reason messages:

```yaml title="config/locales/action_policy.en.yml" ins={7-8}
en:
  action_policy:
    unauthorized: "Sorry, you are not allowed to perform this action"
    policy:
      ticket:
        resolve?: "You are not allowed to resolve this ticket"
        agent_role?: "Customers are not allowed to resolve tickets"
        sufficient_level?: "Your level is insufficient to resolve this ticket"
```

Finally, change the way we generate the exception in `app/controllers/application_controller.rb` to use failure reasons as follows:

```ruby title="app/controllers/application_controller.rb" del={2} ins={3-4}
  rescue_from ActionPolicy::Unauthorized do |ex|
    redirect_back fallback_location: unauthorized_redirect_path, alert: ex.result.message
    redirect_back fallback_location: unauthorized_redirect_path,
      alert: ex.result.reasons.full_messages.to_sentence.presence || ex.result.message
  end
```

Try it:
- **Alice** clicks Resolve → **"Customers are not allowed to resolve tickets"**
- **Bob** clicks Resolve on the billing ticket (level 3) → **"Your level is insufficient to resolve this ticket"**

Different users get different explanations for why they can't act.

### Step 4: Add UI protection with allowance_to

Instead of letting users click a button only to see an error, let's disable it in the UI with a tooltip. Update `app/views/tickets/show.html.erb`—replace the simple button with a three-tier check:

```erb title="app/views/tickets/show.html.erb" del={2-4} ins={5-11}
    <%# Replace the resolve button block %>
    <% if !@ticket.resolved? %>
      <%= button_to "Resolve", resolve_ticket_path(@ticket), method: :patch, class: "btn btn--success" %>
    <% end %>
    <% if !@ticket.resolved? %>
      <% if allowed_to?(:resolve?, @ticket) %>
        <%= button_to "Resolve", resolve_ticket_path(@ticket), method: :patch, class: "btn btn--success" %>
      <% elsif allowed_to?(:resolve?, Ticket) %>
        <button disabled class="btn btn--success" title="<%= allowance_to(:resolve?, @ticket).reasons.full_messages.to_sentence %>">Resolve</button>
      <% end %>
    <% end %>
```

Three levels of checks, all policy-based:

1. `allowed_to?(:resolve?, @ticket)` — can this user resolve **this** ticket? If yes, show an active button.
2. `allowed_to?(:resolve?, Ticket)` — can this user resolve **some** tickets? Passing the `Ticket` class instead of an instance skips the level check (no specific ticket to compare against). If yes, this is an agent with insufficient level — show a disabled button with a tooltip.
3. Neither — this user can never resolve tickets (a customer). Hide the button entirely.

`allowance_to(:resolve?, @ticket)` returns a result object with `.value` (true/false), `.message` (the i18n message) and the `.reasons` object. We use `.reasons.full_messages` for the tooltip text.

### Try it out

- **Bob** on the billing ticket → disabled Resolve button, hover shows "Your level is insufficient to resolve this ticket"
- **Bob** on the password reset ticket (level 1) → active Resolve button
- **Alice** → no Resolve button at all
- **Charlie** (admin) → active Resolve button on every ticket

### Verify with tests

```bash
$ bin/rails test
```

:::tip
Click **Solve** to see the complete code including the resolve route, policy with check?-based reasons, i18n translations, and updated tests.
:::

### What changed

| Concept | What it does |
|---|---|
| `ex.result.message` | Returns the i18n-resolved failure message from the exception |
| `action_policy.unauthorized` | Default fallback i18n key for all denied actions |
| `action_policy.policy.<model>.<rule>?` | Rule-specific i18n message |
| `check?(:rule?)` | Delegates to a sub-rule and records failure reasons |
| `allowance_to(:rule?, record)` | Returns a result object with `.value`, `.message` amd `.reasons` for UI rendering |
