---
type: lesson
title: Creating your first Rails app
editor: false
custom:
  shell:
    workdir: "/workspace/store"
---

Creating Your First Rails App
-----------------------------

Rails comes with several commands to make life easier. Run `rails --help` to see
all of the commands.

`rails new` generates the foundation of a fresh Rails application for you, so
let's start there.

To create our `store` application, run the following command in your terminal:

```bash
$ rails new store
```

:::info
You can customize the application Rails generates by using flags. To see
these options, run `rails new --help`.
:::

After your new application is created, switch to its directory:

```bash
$ cd store
```
