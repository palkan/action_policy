---
type: lesson
title: Pre-checks
focus: /workspace/app/policies/application_policy.rb
custom:
  shell:
    workdir: "/workspace"
---

Pre-checks
-----------

Look at the current policies — `user.admin?` appears in every rule across `TicketPolicy` and `CommentPolicy`. Admins should bypass all authorization checks, but we're checking this individually in every single rule. That's repetitive and error-prone—if someone adds a new rule and forgets the admin check, admins lose access.

Action Policy solves this with **pre-checks**—callbacks that run *before* the rule method. If a pre-check calls `allow!` or `deny!`, the rule itself is never evaluated.

### Step 1: Add a pre-check to ApplicationPolicy

Open `app/policies/application_policy.rb` and add:

```ruby title="app/policies/application_policy.rb"
class ApplicationPolicy < ActionPolicy::Base
  pre_check :allow_admins

  private

  def allow_admins
    allow! if user.admin?
  end
end
```

`allow!` is a special method that immediately grants access and stops further evaluation. Since this pre-check is in `ApplicationPolicy`, it applies to **every policy** that inherits from it—including `TicketPolicy` and `CommentPolicy`.

### Step 2: Simplify TicketPolicy

Now that admins are handled globally, remove `user.admin?` from `TicketPolicy`. And since `destroy?` was only allowed for admins—it becomes simply `false`:

```ruby title="app/policies/ticket_policy.rb" del={8,12-15} ins={9}
class TicketPolicy < ApplicationPolicy
  def show?
    true
  end

  def manage?
    record.user_id == user.id ||
      (user.agent? && record.agent_id == user.id) ||
      user.admin?
      (user.agent? && record.agent_id == user.id)
  end

  def destroy?
    user.admin?
  end
  def destroy? = false
end
```

Wait—`destroy?` returns `false` for everyone? Yes. Non-admin users can never delete tickets, and admin access is already granted by the pre-check before `destroy?` is even called. This is cleaner than a rule that only exists for one role.

### Step 3: Simplify CommentPolicy

Same idea—remove the admin check from `destroy?`:

```ruby title="app/policies/comment_policy.rb" del={3} ins={4}
class CommentPolicy < ApplicationPolicy
  def destroy?
    record.user_id == user.id || user.admin?
    record.user_id == user.id
  end
end
```

### Verify everything still passes

Run the tests:

```bash
$ bin/rails test
```

All tests should pass—the behavior is identical. The pre-check handles the admin case before any rule is evaluated, so the admin tests in `TicketPolicyTest` and `CommentPolicyTest` still succeed.

:::tip
Pre-checks are the right tool for **cross-cutting authorization concerns**—rules that apply to all (or most) policies. Common examples: admin bypass, suspended account denial, or feature flags.
:::

### What changed

| Before | After |
|---|---|
| `user.admin?` in every rule across every policy | One `pre_check :allow_admins` in `ApplicationPolicy` |
| `destroy?` returns `user.admin?` | `destroy?` returns `false` — admins handled by pre-check |
| Adding a new policy requires remembering the admin check | New policies inherit the pre-check automatically |
