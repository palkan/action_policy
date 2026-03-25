---
name: rails-lesson-recipes
description: |
  Use this skill whenever creating a new lesson, choosing a lesson pattern, or validating
  lesson structure. Trigger on: 'create a lesson', 'lesson recipe', 'lesson pattern',
  'terminal-only lesson', 'code editing lesson', 'database lesson', 'console lesson',
  'lesson sequence', 'multi-step lesson', 'validate lesson', 'check lesson', or asking
  how to structure a Rails lesson — even without mentioning recipes. Provides five tested
  blueprints (terminal-only, code-editing, database, full-app, console/IRB) with correct
  frontmatter, directory layouts, content examples, and a post-creation validation
  checklist. Do NOT create lessons without this skill — incorrect structure causes silent
  failures. Do NOT use for frontmatter reference (use tutorial-lesson-config) or file
  organization (use rails-file-management).
---

# Rails Lesson Recipes

Ready-to-use patterns for common Rails tutorial lesson types.

## Recipe 1: Terminal-Only Lesson

**Use for:** Running generators, using the console, exploring CLI tools.
**Example:** `rails new`, `rails console`, `rails generate`.

### Directory Structure

```
1-creating-your-first-rails-app/
  content.md
  _files/
    workspace/
      .keep
```

### Frontmatter

```yaml
---
type: lesson
title: Creating your first Rails app
editor: false
custom:
  shell:
    workdir: "/workspace"
---
```

### Key Decisions

- `editor: false` — the user only interacts via terminal
- `previews: false` — inherited from tutorial root (no server running)
- Empty `workspace/.keep` — user creates the app from scratch
- `workdir: "/workspace"` — terminal starts at the workspace root (before app exists)

### Content Pattern

```markdown
# Creating Your First Rails App

Run the following command to generate a new Rails application:

\`\`\`bash
$ rails new store
\`\`\`

:::info
This may take a moment as Rails generates the application structure.
:::

After your new application is created, switch to its directory:

\`\`\`bash
$ cd store
\`\`\`
```

---

## Recipe 2: Code-Editing Lesson (with Preview)

**Use for:** Writing controllers, models, views, routes — any lesson where the user edits code and sees results.
**Example:** Adding a new action, modifying a view, updating routes.

### Directory Structure

```
3-adding-a-controller/
  content.md
  _files/
    .tk-config.json
    workspace/
      app/
        controllers/
          pages_controller.rb       ← starter/skeleton code
      config/
        routes.rb
  _solution/
    workspace/
      app/
        controllers/
          pages_controller.rb       ← completed code
        views/
          pages/
            home.html.erb           ← new file the user creates
      config/
        routes.rb
```

### Frontmatter

```yaml
---
type: lesson
title: Adding a Controller
focus: /workspace/app/controllers/pages_controller.rb
previews: [3000]
mainCommand: ['node scripts/rails.js server', 'Starting Rails server']
custom:
  shell:
    workdir: '/workspace'
---
```

### `.tk-config.json`

```json
{
  "extends": "../../../../../templates/rails-app"
}
```

### Key Decisions

- `focus` opens the file the user will edit
- `previews: [3000]` shows the Rails app in a preview pane
- `mainCommand` starts the Rails server after prepare commands finish
- `_solution/` includes both modified files and new files the user was asked to create
- Inherits `prepareCommands` (npm install) from tutorial root

### Content Pattern

```markdown
# Adding a Controller

Open `app/controllers/pages_controller.rb` in the editor. Add a `home` action:

\`\`\`ruby title="app/controllers/pages_controller.rb" ins={2-4}
class PagesController < ApplicationController
  def home
    @message = "Welcome to our store!"
  end
end
\`\`\`

Now create the view at `app/views/pages/home.html.erb`:

\`\`\`erb title="app/views/pages/home.html.erb"
<h1><%= @message %></h1>
\`\`\`

:::tip
Click **Solve** to see the completed code if you get stuck.
:::
```

---

## Recipe 3: Database Lesson

**Use for:** Migrations, models, seeds, ActiveRecord queries.
**Example:** Creating a model, running migrations, seeding data.

### Directory Structure

```
1-creating-a-model/
  content.md
  _files/
    .tk-config.json
    workspace/
      db/
        migrate/
          20240101000000_create_products.rb
        seeds.rb
      app/
        models/
          product.rb
```

### Frontmatter

```yaml
---
type: lesson
title: Creating a Product Model
focus: /workspace/app/models/product.rb
previews: [3000]
mainCommand: ['node scripts/rails.js server', 'Starting Rails server']
prepareCommands:
  - ['npm install', 'Preparing Ruby runtime']
  - ['node scripts/rails.js db:prepare', 'Prepare development database']
terminalBlockingPrepareCommandsCount: 2
custom:
  shell:
    workdir: '/workspace'
---
```

### Key Decisions

- `prepareCommands` includes `db:prepare` — this runs migrations and seeds **before** the lesson becomes interactive
- Migration files must have timestamps in filenames (Rails convention)
- Seeds provide starting data so the user sees something immediately
- Override `prepareCommands` at the lesson level (doesn't inherit the tutorial root's single command)

### Content Pattern

```markdown
# Creating a Product Model

Your Product model is defined in `app/models/product.rb`. Let's add validations:

\`\`\`ruby title="app/models/product.rb"
class Product < ApplicationRecord
  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }
end
\`\`\`

The migration has already been run. Try it in the console:

\`\`\`bash
$ bin/rails console
\`\`\`

\`\`\`irb
store(dev)> Product.create(name: "Widget", price: 9.99)
store(dev)> Product.all
\`\`\`
```

---

## Recipe 4: Full-App Lesson (Pre-Built State)

**Use for:** Teaching concepts that require a fully scaffolded app — CRUD, associations, authentication.
**Example:** CRUD operations on an existing scaffold.

### Directory Structure

```
2-crud-operations/
  content.md
  _files/
    .tk-config.json
    workspace/
      .keep
```

### Frontmatter

```yaml
---
type: lesson
title: CRUD Operations
focus: /workspace/app/controllers/products_controller.rb
previews: [3000]
mainCommand: ['node scripts/rails.js server', 'Starting Rails server']
prepareCommands:
  - ['npm install', 'Preparing Ruby runtime']
  - ['node scripts/rails.js db:prepare', 'Prepare development database']
terminalBlockingPrepareCommandsCount: 2
custom:
  shell:
    workdir: '/workspace'
---
```

### `.tk-config.json`

```json
{
  "extends": "../../../../../templates/crud-products"
}
```

### Key Decisions

- Uses `crud-products` template which provides a complete scaffolded app
- `_files/` only contains `.tk-config.json` and a `.keep` — the template provides everything
- `focus` points to the file being discussed in the lesson
- No `_solution/` needed — this is an exploration/explanation lesson, not a coding exercise

---

## Recipe 5: Console/IRB Lesson

**Use for:** Interactive Ruby exploration, testing models, querying the database.

### Directory Structure

```
2-rails-console/
  content.md
  _files/
    .tk-config.json
    workspace/
      .keep
```

### Frontmatter

```yaml
---
type: lesson
title: Rails Console
custom:
  shell:
    workdir: "/workspace"
---
```

### Key Decisions

- No `editor`, no `previews`, no `mainCommand` — user works entirely in the terminal
- Inherits `editor: true` by default but doesn't need to set `editor: false` since the user can still browse files
- Uses a pre-built template via `.tk-config.json` so there's an app to explore

---

## Building Lesson Sequences

### Progressive State Pattern

For a series of lessons that build on each other, use **template layering**:

```
src/templates/
  default/                  ← Base WASM runtime
  rails-app/                ← Empty Rails app (extends default)
  blog-base/                ← Blog app with Post model (extends rails-app)
  blog-with-comments/       ← Blog app + Comment model (extends blog-base)

src/content/tutorial/
  1-blog/
    meta.md                 ← type: part
    1-setup/
      content.md            ← Uses rails-app template
      _files/.tk-config.json → ../../../../../templates/rails-app
    2-posts/
      content.md            ← Uses blog-base template
      _files/.tk-config.json → ../../../../../templates/blog-base
    3-comments/
      content.md            ← Uses blog-with-comments template
      _files/.tk-config.json → ../../../../../templates/blog-with-comments
```

Each template captures the **expected state** at the start of that lesson. This way:
- Users can jump to any lesson without completing previous ones
- Each lesson starts from a known-good state
- Template inheritance keeps file duplication minimal

### When to Create a New Template vs. Use `_files/`

| Create a Template | Use `_files/` |
|-------------------|---------------|
| State is reused by 3+ lessons | Only this lesson needs these files |
| State is complex (many files) | Just 1-3 files differ from the template |
| You want users to jump to this lesson directly | Sequential lessons where order matters |

### Lesson-to-Lesson Expectations

**Always assume each lesson starts fresh.** The WASM runtime reinstalls on lesson navigation. Design each lesson to be self-contained:

1. Use `prepareCommands` for setup (npm install, db:prepare) and `terminalBlockingPrepareCommandsCount: <number of commands>` to ensure terminal is not used before the prepare commands finish.
2. Use templates or `_files/` for starting code state
3. Don't rely on user actions from a previous lesson

## Post-Creation Checklist

After creating a lesson, verify these structural requirements. Violations cause silent failures at runtime.

### Required

- [ ] `content.md` exists in the lesson directory and has `type: lesson` in frontmatter
- [ ] `content.md` has a `title` in frontmatter
- [ ] All file paths in `_files/` start with `workspace/` (not `/workspace/`)
- [ ] All file paths in `_solution/` start with `workspace/` (not `/workspace/`)
- [ ] If `.tk-config.json` exists in `_files/`, its `extends` path resolves to an existing template directory under `src/templates/`
- [ ] `_solution/` mirrors the `_files/` directory structure (paths must match for "Solve" to replace correctly)
- [ ] `custom.shell.workdir` is set on the lesson itself (it does NOT inherit from parent `meta.md`)

### If previews are enabled

- [ ] `previews` is set (e.g., `previews: [3000]`)
- [ ] `mainCommand` is set to start the server (e.g., `['node scripts/rails.js server', 'Starting Rails server']`)
- [ ] `prepareCommands` includes `npm install` (either inherited from tutorial root or set explicitly)

### If database is used

- [ ] `prepareCommands` includes **both** `npm install` and `node scripts/rails.js db:prepare` (remember: arrays replace, not merge)
- [ ] Migration files have timestamp prefixes in filenames
- [ ] Seeds file exists if the lesson needs starting data

### If focus is set

- [ ] `focus` path is absolute from WebContainer root (e.g., `/workspace/app/...`)
- [ ] The file at `focus` path exists in `_files/` or in the referenced template
- [ ] `editor` is not set to `false` (focus is silently ignored when editor is hidden)

### Path verification

- [ ] `.tk-config.json` `extends` uses correct `../` count: 4 + number of intermediate levels above the lesson (typically 5 for `tutorial/part/lesson/_files/`)
- [ ] `focus` paths use `/workspace/...` (absolute), while `_files/` paths use `workspace/...` (relative, no leading slash)
- [ ] `scope` paths use `/workspace/...` (absolute)
