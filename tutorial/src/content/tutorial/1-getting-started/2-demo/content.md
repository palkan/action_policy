---
type: lesson
title: Meet the Demo App
previews:
  - 3000
custom:
  shell:
    workdir: "/workspace"
---

Meet HelpDesk
-------------------

On the right side of the screen, you can see a running Rails application — **HelpDesk**, a support ticket management system you'll be working with throughout the tutorial.

The app has three user roles:

| User | Role | Description |
|---|---|---|
| **Alice** | Customer | Submits and tracks support tickets |
| **Bob** | Agent  | Handles and responds to tickets |
| **Charlie** | Admin  | Full access to manage everything |

### Try it out

Launch the Rails server:

```bash
$ bin/rails s
```

:::tip
The server starts automatically whenever you click on the application URL, e.g., [localhost:3000](http://localhost:3000) (only if the terminal is ready).
:::

Sign in using one of the quick login links (or use the credentials below):

| Email | Password | Role |
|---|---|---|
| `alice@example.org` | `s3cr3t` | Customer |
| `bob@example.org` | `s3cr3t` | Agent |
| `charlie@example.org` | `s3cr3t` | Admin |

After signing in, you'll be redirected to the **Tickets** page. Try creating a ticket, adding a comment, or editing existing ones.

### Notice something?

Right now, **every user can do everything** — any user can edit or delete any ticket, read internal comments, and assign agents. There are no access controls in place (check out the `app/controllers/tickets_controller.rb` file).

That's exactly the problem we'll solve in this tutorial using **Action Policy**.

### Using the terminal

You can also interact with the app through the terminal below the preview. Try opening a Rails console:

```bash
$ bin/rails console
```

Try listing users with their roles:

```irb
helpdesk(dev)> User.pluck(:name, :role)
```

### Running tests

You can run Rails tests from the terminal as usual. For example, run the TicketsController integration tests:

```bash
$ bin/rails test test/integration/tickets_test.rb
```
