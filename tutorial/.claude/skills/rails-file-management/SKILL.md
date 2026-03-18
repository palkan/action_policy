---
name: rails-file-management
description: |
  Use this skill whenever organizing files for Rails tutorial lessons — _files/, _solution/,
  templates, workspace paths. Trigger on: 'create _files', 'add _solution', 'template
  inheritance', '.tk-config.json', 'extends path', 'workspace path', 'which files go where',
  'add a gem', 'Gemfile', 'build-wasm', 'create a template', 'protected files', 'do not
  override', or asking where to put Rails app code — even without mentioning file management.
  Covers the three-layer merge model, built-in templates, `.tk-config.json` path formula for
  different nesting depths, protected infrastructure files, and WASM gem build workflow. Do
  NOT attempt file organization without this skill. Do NOT use for frontmatter (use
  tutorial-lesson-config) or content hierarchy (use tutorial-content-structure).
---

# Rails File Management

How to organize files across templates, `_files`, and `_solution` directories for Rails tutorial lessons.

## The File Layering Model

When a lesson loads, TutorialKit merges files from multiple sources in this order:

```
Template (base)        ← Runtime infrastructure, package.json, bin/, lib/
  ↓ overlaid by
_files/ (lesson)       ← Lesson-specific Rails app code
  ↓ replaced on "Solve"
_solution/ (lesson)    ← Completed/answer code
```

Files from each layer **overlay** the previous — same-path files are replaced, new files are added.

**Two template mechanisms (don't confuse them):**
- **`template` frontmatter field** (e.g., `template: default`) — selects which base template JSON is loaded as the "Template (base)" layer. Almost always set in the part's `meta.md`. The tutorial's root `meta.md` contains `rails-app`—a minimal demo app used in the tutotiral.
- **`_files/.tk-config.json` with `extends`** — extends the `_files` layer with files from another template directory. These provide the source code that overlays on top of the template used. Use it to share many files between lessons. Otherwise, prefer duplication and the `template` frontmatter..

IMPORTANT: Files added via the `template` frontmatter are not visible in the editor; only the `_files` contents (including `_files/.tk-config.json`'s contents) are shown in the editor.

## Templates

Templates live in `src/templates/` and provide the base project structure for WebContainer.

### Built-in Templates

| Template | Purpose | Inherits From |
|----------|---------|---------------|
| `default` | Base Rails WASM runtime — Node.js wrappers, Express server, PGLite, WASM loader. Selected via `template: default` in frontmatter (the default). | (none) |
| `rails-app` | Pre-generated Rails app at `workspace/`. Update this template to set up the base Rails app for the tutorial | `default` |

### Template Inheritance

Templates can extend other templates via `.tk-config.json`:

```json
{
  "extends": "../rails-app"
}
```

The child template's files overlay on top of the parent's files.

### Creating a New Template

Create a directory under `src/templates/` with:

1. A `.tk-config.json` extending the appropriate parent
2. The files that differ from the parent

**Example:** A template for a blog tutorial:

```
src/templates/blog-app/
  .tk-config.json          → { "extends": "../rails-app" }
  workspace/
    app/
      models/post.rb
      controllers/posts_controller.rb
      views/posts/
        index.html.erb
        show.html.erb
    config/routes.rb
    db/
      migrate/001_create_posts.rb
      seeds.rb
```

### What Belongs in a Template vs. a Lesson

| In a Template | In a Lesson's `_files/` |
|---------------|------------------------|
| Shared app structure used by multiple lessons | Files specific to one lesson |
| Models, migrations, seeds for a baseline state | Modifications the user will build upon |
| Routes and config shared across a chapter | One-off configuration changes |
| Complete working app states (scaffolded code) | Starter/skeleton files the user will complete |

**Rule of thumb:** If 3+ lessons need the same base state, create a template. If only one lesson uses it, put it in `_files/`.

## `_files/` Directory

The `_files/` directory contains files shown to the user when the lesson loads. These are the **starting state** for the lesson.

### Path Convention

All Rails app files **must** live under `workspace/` to match the WASI preopen at `/workspace`:

```
_files/
  workspace/
    app/
      controllers/
        products_controller.rb
      models/
        product.rb
      views/
        products/
          index.html.erb
    config/
      routes.rb
```

### `.tk-config.json` Path Formula

The `extends` path in `.tk-config.json` is **relative to the directory containing the `.tk-config.json` file**. To reach `src/templates/<name>`, count the `../` segments based on your content nesting depth:

| Content structure | `../` count | Example `extends` value |
|-------------------|-------------|------------------------|
| `tutorial/lesson/_files/` | 4 | `"../../../../templates/rails-app"` |
| `tutorial/part/lesson/_files/` | 5 | `"../../../../../templates/rails-app"` |
| `tutorial/part/chapter/lesson/_files/` | 6 | `"../../../../../../templates/rails-app"` |

The count is: 1 (`_files/`) + 1 (lesson dir) + N (intermediate dirs: part, chapter) + 1 (`tutorial/`) + 1 (`content/`) = **4 + number of intermediate levels**.

For the standard `tutorial/part/lesson/_files/` structure used by most Rails tutorials, the path is always `"../../../../../templates/<name>"` (5 segments).

## `_solution/` Directory

The `_solution/` directory contains the **completed code** for the lesson. When the user clicks "Solve", solution files replace the corresponding `_files/`.

### Structure

Mirror the `_files/` directory structure:

```
_solution/
  workspace/
    store/
      app/
        controllers/
          products_controller.rb      ← completed version
```

### When to Use

- **Code-editing lessons** where the user modifies files — provide the finished version
- **Not needed** for terminal-only lessons (e.g., running `rails new`, using the console)

### Tips

- `_solution/` can include files not present in `_files/` (e.g., a new file the user was asked to create)
- Only include files that differ from the template + `_files/` — unchanged files don't need to appear

## Do Not Override These Files

The following files are **runtime infrastructure** provided by the `default` template. Lessons should never include these in `_files/` or `_solution/`:

| Path | Purpose |
|------|---------|
| `package.json` | npm dependencies (WASM runtime, Express, PGLite) |
| `bin/rails`, `bin/ruby`, `bin/console`, `bin/rackup` | Node.js CLI wrappers |
| `lib/rails.js`, `lib/server.js`, `lib/database.js` | WASM runtime, HTTP bridge, DB |
| `lib/boot-progress.js`, `lib/commands.js`, `lib/irb.js` | Boot progress, command dispatch, IRB |
| `lib/server/frame_location_middleware.js` | Express middleware for frame location |
| `lib/patches/authentication.rb` | Auto-login patch |
| `lib/patches/app_generator.rb` | Rails generator WASM compat patch |
| `scripts/` | Build and automation scripts |
| `pgdata/` | PGLite database storage |

## Managing Gems

### Adding Gems

Gems are compiled into the WASM binary. To add a gem:

1. Edit `ruby-wasm/Gemfile` in the project root
2. Run `bin/build-wasm` to rebuild the WASM binary

```ruby
# ruby-wasm/Gemfile
source "https://rubygems.org"

gem "wasmify-rails", "~> 0.4.0"
gem "rails", "~> 8.0.0"

# Add your gems here
gem "devise"              # Authentication
gem "friendly_id"         # Slugs
gem "pagy"                # Pagination
```

### Gem Constraints

- **Pure Ruby gems** work without issues
- **Gems with native C extensions** need WASM-compatible builds — many common ones are already shimmed (see `rails-wasm-author-constraints` skill)
- Rebuilding the WASM binary takes several minutes
- The resulting binary is ~80MB and includes all gems

### Gemfile in Templates

The `ruby-wasm/Gemfile` is the **single source of truth** for which gems are available. Individual lessons cannot add gems at runtime — the Gemfile is baked into the WASM binary at build time.

If your tutorial teaches the user to "add a gem to the Gemfile", be aware that this is a **conceptual exercise** — the gem must already be compiled into the WASM binary for it to actually work when they run `bundle install`.
