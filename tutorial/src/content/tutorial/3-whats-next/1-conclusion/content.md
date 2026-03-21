---
type: lesson
title: Conclusion
previews:
  - 3000
custom:
  shell:
    workdir: "/workspace"
---

Conclusion
----------

Congratulations! You've built a fully authorized Rails application from the ground up using Action Policy. Starting from a completely open Help Desk app, you've progressively added:

- **Policies and rules** — centralized authorization logic in dedicated policy classes
- **Controller integration** — `authorize!` to enforce access, `authorized_scope` to filter collections
- **View helpers** — `allowed_to?` and `allowance_to` for conditional UI rendering
- **Pre-checks** — cross-cutting concerns like admin bypass, applied globally
- **Scoping** — `relation_scope` to filter ActiveRecord queries per user
- **Failure reasons** — `check?`-based sub-rules with per-reason i18n messages
- **Testing** — policy unit tests and controller integration tests

### Keep exploring

The demo app on the right is fully functional—you can sign in as different users, create tickets, add comments, and see how authorization rules shape the experience. Try adding new rules or modifying existing ones to see what happens.

Here are some ideas to try:

- Add a `close?` rule that only allows the ticket creator or an admin to close a ticket
- Add a `reassign?` rule for agents to transfer tickets to other agents
- Make the `internal` checkbox on the comment form visible only to agents

### Features not covered

This tutorial focused on the most commonly used features. Action Policy has more to offer — here's what we didn't cover:

| Feature | What it does | Documentation |
|---------|-------------|---------------|
| Caching | Cache policy results to avoid redundant checks | [Caching](https://actionpolicy.evilmartians.io/guide/caching) |
| Namespaces | Organize policies by namespace (e.g., Admin::TicketPolicy) | [Namespaces](https://actionpolicy.evilmartians.io/guide/namespaces) |
| Instrumentation | Hook into policy evaluation for monitoring | [Instrumentation](https://actionpolicy.evilmartians.io/guide/instrumentation) |
| GraphQL integration | Use Action Policy with GraphQL APIs | [GraphQL](https://actionpolicy.evilmartians.io/guide/graphql) |

Visit [actionpolicy.evilmartians.io](https://actionpolicy.evilmartians.io) for the full documentation and API reference.
