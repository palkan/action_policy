---
type: lesson
title: Authorization in Views
focus: /workspace/app/views/tickets/show.html.erb
previews:
  - 3000
custom:
  shell:
    workdir: "/workspace"
---

Authorization in Views
-----------------------

The controllers now reject unauthorized actions — but the UI still shows Edit and Delete buttons to everyone. Clicking a button you're not allowed to use results in a redirect with an error message. That's a poor user experience.

Start the server and see the problem yourself:

```bash
$ bin/rails s
```

Sign in as **Alice** (customer) and open one of her tickets — you should see both Edit and Delete buttons at the top of the page as well as Delete buttons for each comment... Wait, Alice shouldn't see Delete (only admins can delete tickets and comments). Try clicking them—you should be redirected back to the ticket page with the "Unauthorized" message.

Let's fix this.

Action Policy provides the `allowed_to?` helper for views. It takes a rule name and a record, and returns `true` or `false` — using the same policy classes you already wrote.

### Step 1: Wrap ticket actions

Open `app/views/tickets/show.html.erb`. Find the Edit and Delete buttons at the top and wrap each one with an `allowed_to?` check:

```erb title="app/views/tickets/show.html.erb"
<div class="inline-actions">
  <% if allowed_to?(:edit?, @ticket) %>
    <%= link_to "Edit", edit_ticket_path(@ticket), class: "btn" %>
  <% end %>
  <% if allowed_to?(:destroy?, @ticket) %>
    <%= button_to "Delete", @ticket, method: :delete, class: "btn btn--danger", data: {turbo_confirm: "Are you sure?"} %>
  <% end %>
</div>
```

Now, go to the ticket page again—there should not be "Delete" button anymore. Let's see what's accessible to others.

Now sign in as **Bob** (agent) and open the "Billing" ticket (assigned to Bob) — Edit should be visible. Then open "Can not reset my password" (not assigned to Bob) — Edit should be hidden.

Sign in as **Charlie** (admin) — both Edit and Delete should appear on every ticket.

### Step 2: Wrap comment delete button

Now, log in as Alice again—remember she saw Delete buttons for all comments, too? Let's hide them.

Open `app/views/comments/_comment.html.erb`. Wrap the Delete button:

```erb title="app/views/comments/_comment.html.erb"
<% if allowed_to?(:destroy?, comment) %>
  <%= button_to "Delete", ticket_comment_path(comment.ticket, comment), method: :delete, class: "btn btn--small btn--danger" %>
<% end %>
```

Now only the comment author and admins see the Delete button for each comment.

### How it works

`allowed_to?` in views uses the **same policies and rules** as `authorize!` in controllers:

| View helper | Controller equivalent |
|---|---|
| `allowed_to?(:edit?, @ticket)` | `authorize! @ticket` in edit action → `TicketPolicy#update?` (via alias) |
| `allowed_to?(:destroy?, @ticket)` | `authorize! @ticket` in destroy action → `TicketPolicy#destroy?` |
| `allowed_to?(:destroy?, comment)` | `authorize! @comment` in set_comment → `CommentPolicy#destroy?` |

This is a key benefit of Action Policy: **one set of rules, used everywhere** — controllers, views, and (later) tests. No more duplicated conditionals.
