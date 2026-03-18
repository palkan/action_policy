---
type: lesson
title: Meet the Demo App
focus: /workspace/app/views/home/index.html.erb
previews:
  - 3000
custom:
  shell:
    workdir: "/workspace"
---

Exploring the demo app
-------------------

On the right side of the screen, you can see a running Rails application — this is the **demo app** you'll be working with throughout the tutorial.

The app is pre-configured with:

- **Authentication** — a simple session-based login system
- **Users** — two sample accounts you can sign in with
- **An editor** — browse and edit source files above the preview

### Try it out

Launch the Rails server:

```bash
$ bin/rails s
```

Click the **"Sign in to get started"** button in the preview, and log in with one of the sample accounts using the quick login links. You can also check the full login flow and use the following login credentials:

| Email | Password |
|---|---|
| `alice@example.org` | `s3cr3t` |
| `bob@example.org` | `s3cr3t` |

After signing in, you'll see the home page greets you by name. Feel free to update the home page ERB template and reload the page—the changes are picked up by the server!

### Using the terminal

You can also interact with the app through the terminal below the preview. Try opening a Rails console:

```bash
$ bin/rails console
```

You should see a prompt like:

```irb
Loading development environment (Rails 8.0.2)
demo_app(dev)>
```

Try listing users:

```irb
demo_app(dev)> User.pluck(:name, :email_address)
```

In the next lessons, we'll turn this blank canvas into something cool.
