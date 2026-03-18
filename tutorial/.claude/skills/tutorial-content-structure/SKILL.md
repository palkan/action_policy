---
name: tutorial-content-structure
description: |
  Use this skill whenever organizing tutorial content into parts, chapters, and lessons.
  Trigger when the user says 'create a lesson', 'create a chapter', 'create a part', 'add
  a lesson', 'tutorial structure', 'content.md', 'meta.md', 'lesson ordering', 'callout',
  ':::tip', ':::info', ':::warn', 'code import', 'expressive code', or asks about the
  content hierarchy, directory naming, or markdown features — even if they don't explicitly
  mention content structure. This skill documents TutorialKit's specific directory conventions,
  metadata file roles (meta.md vs content.md), numeric prefix ordering, the recommended
  tutorial root config for Rails, callout syntax with all attributes, code block file imports,
  and expressive code features. These are framework-specific patterns that cannot be inferred
  from general knowledge. Do NOT use for frontmatter option reference (use
  tutorial-lesson-config) or file/template organization (use rails-file-management).
---

# Tutorial Content Structure

How to organize interactive Ruby on Rails tutorials using TutorialKit's content hierarchy.

## Content Hierarchy

Tutorials use a directory-based hierarchy under `src/content/tutorial/`:

```
src/content/tutorial/
  meta.md                          # Tutorial root config (type: tutorial)
  1-getting-started/               # Part
    meta.md                        # Part config (type: part)
    1-first-rails-app/             # Lesson (or Chapter, if it contains lessons)
      content.md                   # Lesson content (type: lesson)
      _files/                      # Initial code files
      _solution/                   # Solution code files
    2-rails-console/
      content.md
      _files/
```

The full hierarchy is **Tutorial > Parts > Chapters > Lessons**, but you can skip levels:

| Structure | When to Use |
|-----------|-------------|
| Parts > Chapters > Lessons | Large tutorials with major sections and subsections |
| Parts > Lessons | Medium tutorials grouped by topic |
| Lessons only | Small tutorials or quick guides |

## Directory Naming

Directories use **numeric prefixes** for ordering: `1-basics/`, `2-controllers/`, `3-views/`.

- The number determines display order in navigation
- The text after the number becomes part of the URL slug
- Use kebab-case: `1-creating-your-first-rails-app/`

## Metadata Files

### `meta.md` — Tutorial Root

Every tutorial needs a root `meta.md` at `src/content/tutorial/meta.md`. This sets **inherited defaults** for all lessons:

```yaml
---
type: tutorial
prepareCommands:
  - ['npm install', 'Preparing Ruby runtime']
terminalBlockingPrepareCommandsCount: 1
previews: false
filesystem:
  watch: ['/*.json', '/workspace/**/*']
terminal:
  open: true
  activePanel: 0
  panels:
    - type: terminal
      id: 'cmds'
      title: 'Command Line'
      allowRedirects: true
    - ['output', 'Setup Logs']
---
```

**Important for Rails tutorials:** The config above is the recommended baseline. It sets up `npm install` as a blocking prepare command (downloads the ~80MB WASM runtime), watches `/workspace/**/*` for file changes, and configures a persistent terminal with setup log output.

### `meta.md` — Parts and Chapters

Parts and chapters each get a `meta.md`:

```yaml
---
type: part
title: Getting Started with Rails
---
```

```yaml
---
type: chapter
title: Models and Databases
---
```

Parts and chapters can also set inherited configuration (same options as tutorial root). Any setting here overrides the tutorial default for all lessons within.

### `content.md` — Lessons

Each lesson directory contains a `content.md` with frontmatter and markdown body:

```yaml
---
type: lesson
title: Creating your first Rails app
editor: false
custom:
  shell:
    workdir: "/workspace/store"
---

# Your lesson content here

Write instructions, explanations, and code examples in standard markdown.
```

## Explicit Ordering

Instead of relying on numeric prefixes, you can explicitly order children in `meta.md`:

```yaml
---
type: tutorial
parts:
  - getting-started        # matches folder name (without numeric prefix)
  - controllers
  - views
---
```

```yaml
---
type: part
title: Getting Started
lessons:
  - creating-your-first-rails-app
  - rails-console
---
```

When using explicit ordering, folder names don't need numeric prefixes.

## Markdown Features

### Callouts

```markdown
:::tip
Rails follows RESTful conventions, making your applications predictable.
:::

:::info
You can customize the application Rails generates by using flags.
:::

:::warn
This operation will reset the database.
:::

:::danger
Never expose your secret_key_base in production.
:::

:::success
Your Rails app is running!
:::
```

Callouts support optional attributes:

```markdown
:::tip{title="Pro Tip"}
Custom title for the callout.
:::

:::info{noBorder=true}
Borderless callout style.
:::

:::warn{hideTitle=true}
Only the message, no title bar.
:::

:::danger{hideIcon=true}
Title shown but no icon.
:::

:::tip{class="my-custom-class"}
Custom CSS class on the callout container.
:::
```

| Attribute | Effect |
|-----------|--------|
| `title` | Custom title text (replaces default like "Tip", "Info") |
| `noBorder` | `"true"` removes the left border |
| `hideTitle` | `"true"` hides the entire title bar |
| `hideIcon` | `"true"` hides the icon but keeps the title |
| `class` | Additional CSS classes on the callout container |

### Code Block File Imports

Inline the contents of lesson files directly in your markdown:

~~~markdown
```file:/workspace/store/app/controllers/products_controller.rb
```
~~~

This renders the contents of the file from the lesson's `_files/` directory. For solution files:

~~~markdown
```solution:/workspace/store/app/controllers/products_controller.rb
```
~~~

### Expressive Code Attributes

Code blocks support highlighting, line annotations, and framing:

~~~markdown
```ruby title="app/models/product.rb" showLineNumbers
class Product < ApplicationRecord
  validates :name, presence: true     # [!code highlight]
  validates :price, numericality: { greater_than: 0 }
end
```
~~~

Available attributes:

| Attribute | Example | Effect |
|-----------|---------|--------|
| `title` | `title="config/routes.rb"` | Shows filename header |
| `showLineNumbers` | `showLineNumbers` | Display line numbers |
| `ins={lines}` | `ins={2-3}` | Mark lines as inserted (green) |
| `del={lines}` | `del={5}` | Mark lines as deleted (red) |
| `{lines}` | `{1,3-5}` | Highlight specific lines |
| `collapse={range}` | `collapse={1-5}` | Collapse line range |
| `frame="terminal"` | `frame="terminal"` | Terminal-style frame |

### Rails path links

Inline code matching Rails path patterns (`app/`, `db/`, `config/`, `test/`) is automatically converted into clickable buttons that open the file in the editor:

```markdown
Open `app/models/user.rb` to see the User model.
```

This is handled by the `remarkRailsPathLinks` plugin. Only paths starting with `app/`, `db/`, `config/`, or `test/` are matched.

### Links

Standard markdown links work. For linking to the running app preview:

```markdown
Visit [the home page](http://localhost:3000) to see the result.
```

### MDX Support

Rename `content.md` to `content.mdx` to use MDX features (component imports, JSX in markdown).

## Styling Rails Views in Lessons

The `rails-app` template includes a CSS design system with BEM components and CSS custom properties. When writing ERB views in `_files/` or `_solution/`, use these classes for consistent styling without adding custom CSS.

### Common Patterns

**Page with a list (index view):**

```erb
<div class="page-header">
  <h1>Tickets</h1>
  <%%= link_to "New Ticket", new_ticket_path, class: "btn btn--primary" %>
</div>

<div class="card">
  <table class="table">
    <thead>
      <tr>
        <th>Title</th>
        <th>Status</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <%% @tickets.each do |ticket| %>
        <tr>
          <td><%%= link_to ticket.title, ticket %></td>
          <td><span class="badge badge--primary"><%%= ticket.status %></span></td>
          <td class="inline-actions">
            <%%= link_to "Edit", edit_ticket_path(ticket), class: "btn btn--small" %>
          </td>
        </tr>
      <%% end %>
    </tbody>
  </table>
</div>
```

**Detail page (show view):**

```erb
<div class="page-header">
  <h1><%%= @ticket.title %></h1>
  <div class="inline-actions">
    <%%= link_to "Edit", edit_ticket_path(@ticket), class: "btn btn--small" %>
    <%%= link_to "Back", tickets_path, class: "btn btn--small" %>
  </div>
</div>

<div class="card mb-md">
  <div class="card__body">
    <p><%%= @ticket.description %></p>
    <p class="text-muted text-sm">
      Created by <%%= @ticket.user.name %> &middot;
      <span class="badge badge--primary"><%%= @ticket.status %></span>
    </p>
  </div>
</div>
```

**Form:**

```erb
<div class="card">
  <div class="card__header">
    <h2>New Ticket</h2>
  </div>
  <div class="card__body">
    <%%= form_with model: @ticket do |form| %>
      <div class="form__group">
        <%%= form.label :title, class: "form__label" %>
        <%%= form.text_field :title, class: "input" %>
      </div>

      <div class="form__group">
        <%%= form.label :description, class: "form__label" %>
        <%%= form.text_area :description, class: "input" %>
      </div>

      <div class="form__actions">
        <%%= form.submit "Create", class: "btn btn--primary" %>
        <%%= link_to "Cancel", tickets_path, class: "btn" %>
      </div>
    <%% end %>
  </div>
</div>
```

**Flash messages** are handled automatically by the layout. Controllers just use `redirect_to ..., notice: "..."` or `alert: "..."`.

### Quick Reference

| Need | Classes |
|------|---------|
| Primary action button | `btn btn--primary` |
| Destructive action | `btn btn--danger` |
| Small inline button | `btn btn--small` |
| Text input / textarea / select | `input` |
| Wrap content in a box | `card` > `card__body` |
| Box with title | `card` > `card__header` + `card__body` |
| Status label | `badge badge--primary` (or `--success`, `--danger`, `--warning`) |
| Data table | `table` |
| Title + action row | `page-header` |
| Form field wrapper | `form__group` > `form__label` + `input` |
| Muted helper text | `text-muted text-sm` |
| Row of buttons/links | `inline-actions` |

See the `tutorial-quickstart` skill for the full CSS custom properties reference and the complete component list.
