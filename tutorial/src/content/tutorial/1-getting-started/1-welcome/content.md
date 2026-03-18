---
type: lesson
title: Welcome to Action Policy tutorial
editor: false
terminal: false
custom:
  shell:
    workdir: "/workspace"
---

Welcome!
--------

This tutorial teaches you how to use [Action Policy](https://actionpolicy.evilmartians.io)—an authorization framework for Ruby and Rails—to manage access control in a structured, maintainable way.

### What you'll build

You'll work with a **Help Desk** application where authorization requirements grow over time. Starting from zero access control, you'll progressively add policies, scoping, testing, and user-friendly error messages using Action Policy.

Along the way, you'll learn how to:

- Define **policy classes** with rule methods
- Use **pre-checks** and **aliases** to keep policies DRY
- **Scope** records so users only see what they're allowed to
- **Test** policies and authorizations with Action Policy's built-in test helpers
- Provide **failure reasons** so users understand _why_ they can't do something

### How to use this tutorial

The tutorial environment comes with the following components:

- **Lesson** (left): lesson contents
- **Editor** (right top): browse and edit source files
- **Preview** (right middle): see the running Rails app
- **Terminal** (right bottom): run commands (`bin/rails console`, tests, etc.)

Each lesson builds on the previous one. You can either follow the steps in order—the app state carries forward between lessons—or you can go to any lesson and use the default source code for the lesson.

:::info
You need basic familiarity with Ruby and Rails to follow along. No prior Action Policy experience is required.
:::
