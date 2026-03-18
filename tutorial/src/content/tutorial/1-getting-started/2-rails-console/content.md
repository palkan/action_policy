---
type: lesson
title: Rails Console
custom:
  shell:
    workdir: "/workspace/store"
---

Rails Console
-------------------

Now that we have created our products table, we can interact with it in Rails.
Let's try it out.

For this, we're going to use a Rails feature called the *console*. The console
is a helpful, interactive tool for testing our code in our Rails application. Run the following command in the terminal:

```bash
$ bin/rails console
```

You should see a prompt like the following:

```irb
Loading development environment (Rails 8.0.2)
store(dev)>
```

Now we can type code that will be executed when we hit `Enter`. Try
printing out the Rails version:

```irb
store(dev)> Rails.version
<!-- hit Enter -->
```

If the line "8.0.2" appears, it works!
