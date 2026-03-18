---
type: lesson
title: Meet the Demo
focus: /workspace/app/views/home/index.html.erb
previews:
  - 3000
custom:
  shell:
    workdir: "/workspace"
---

Exploring our demo application
-------------------

TBD

You can use Rails console:

```bash
$ bin/rails console
```

You should see a prompt like the following:

```irb
Loading development environment (Rails 8.0.2)
helpdesk(dev)>
```

Now we can type code that will be executed when we hit `Enter`. Try
printing out the number of users in the database:

```irb
store(dev)> User.count
<!-- hit Enter -->
```
