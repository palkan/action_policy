---
name: tutorial-lesson-config
description: |
  Use this skill whenever configuring lesson frontmatter or checking inheritance rules.
  Trigger on: 'frontmatter', 'prepareCommands', 'mainCommand', 'editor config', 'terminal
  config', 'preview config', 'configuration inheritance', 'focus file', 'i18n', 'allowEdits',
  'previews', 'autoReload', 'scope', 'defaults', 'what inherits', 'does X inherit',
  'invalid combination', 'constraint', or any YAML frontmatter question — even without
  mentioning configuration. Authoritative reference for all frontmatter options, inheritance
  rules, defaults, and invalid-combination constraints with Rails-specific patterns. Do NOT
  guess frontmatter without this skill. Do NOT use for content hierarchy
  (use tutorial-content-structure) or file organization (use rails-file-management).
---

# Tutorial Lesson Configuration

Complete reference for configuring lessons, with Rails-specific defaults and patterns.

## Configuration Cascade

Configuration **inherits downward**: Tutorial > Part > Chapter > Lesson. Set shared defaults at the tutorial level; override per-lesson as needed.

```
meta.md (type: tutorial)     ← base defaults for all lessons
  meta.md (type: part)       ← overrides for this part's lessons
    meta.md (type: chapter)  ← overrides for this chapter's lessons
      content.md (type: lesson) ← final per-lesson overrides
```

**Rails convention:** Set these once in the tutorial root `meta.md`:

```yaml
prepareCommands:
  - ['npm install', 'Preparing Ruby runtime']
terminalBlockingPrepareCommandsCount: 1
previews: false
filesystem:
  watch: ['/*.json', '/workspace/**/*']
terminal:
  open: true
  panels:
    - type: terminal
      id: 'cmds'
      title: 'Command Line'
      allowRedirects: true
    - ['output', 'Setup Logs']
```

Then override only what changes per-lesson (e.g., enable `previews: [3000]` for lessons with a running server).

## Inheritance Rules

### Properties That Inherit (via cascade)

These properties are resolved through the cascade (Tutorial → Part → Chapter → Lesson). The **most specific** (lesson-level) value wins. For plain objects, child and parent are deep-merged; for arrays and primitives, the child **replaces** the parent entirely.

| Property | Merge behavior |
|----------|---------------|
| `mainCommand` | Replace |
| `prepareCommands` | **Replace** (not merge — if a lesson sets this, it completely overrides the parent) |
| `terminalBlockingPrepareCommandsCount` | Replace |
| `previews` | Replace |
| `autoReload` | Replace |
| `template` | Replace |
| `terminal` | Deep-merge if both are objects; replace if either is a primitive (`true`/`false`) |
| `editor` | Deep-merge if both are objects; replace if either is a primitive |
| `focus` | Replace |
| `i18n` | Deep-merge (lesson keys override parent keys; unset keys fall through) |
| `meta` | Deep-merge |
| `editPageLink` | Replace |
| `openInStackBlitz` | Replace |
| `downloadAsZip` | Replace |
| `filesystem` | Deep-merge |

### Properties That Do NOT Inherit

These are **per-lesson only** and must be set on each lesson that needs them:

| Property | Why no inheritance |
|----------|-------------------|
| `custom` (including `custom.shell.workdir`) | Not in the cascade — set it on every lesson |
| `scope` | Lesson-specific file tree filter |
| `hideRoot` | Lesson-specific file tree option |

**Critical:** `custom.shell.workdir` must be set on **every lesson** that needs a custom terminal working directory. It will NOT be inherited from a part or tutorial `meta.md`.

**Critical:** When a lesson overrides `prepareCommands`, it **replaces** the entire array from the parent. If the tutorial root sets `prepareCommands: [['npm install', 'Preparing Ruby runtime']]` and a lesson needs to add `db:prepare`, the lesson must include **both** commands:

```yaml
# WRONG — npm install is lost
prepareCommands:
  - ['node scripts/rails.js db:prepare', 'Prepare database']

# CORRECT — include all commands
prepareCommands:
  - ['npm install', 'Preparing Ruby runtime']
  - ['node scripts/rails.js db:prepare', 'Prepare database']
```

## Editor Configuration

### Show/Hide Editor

```yaml
editor: false           # Hide editor entirely (terminal-only lessons)
editor: true            # Show editor (default)
```

### File Tree Options

```yaml
editor:
  fileTree: false                      # Hide file tree, show only editor tabs
  fileTree:
    allowEdits: true                   # Allow creating files/folders anywhere
    allowEdits: "/workspace/**"        # Allow edits matching glob
    allowEdits:                        # Multiple glob patterns
      - "/workspace/store/app/**"
      - "/workspace/store/config/**"
```

### Focus File

Auto-open a specific file in the editor when the lesson loads:

```yaml
focus: /workspace/store/app/controllers/products_controller.rb
```

**Path must be absolute** from the WebContainer root. For Rails apps, this is typically `/workspace/<app-name>/...`.

### File Tree Scope and Root

```yaml
scope: /workspace/store        # Only show files under this path in the tree
hideRoot: true                 # Hide the "/" root node (default: true)
```

`scope` is useful to avoid exposing infrastructure files (`bin/`, `lib/`, `scripts/`) to tutorial users.

## Terminal Configuration

### Basic

```yaml
terminal: false     # Hide terminal entirely
terminal: true      # Show with defaults
```

### Panel Configuration

```yaml
terminal:
  open: true              # Open terminal panel by default
  activePanel: 0          # Which tab is active (0-indexed)
  panels:
    - type: terminal      # Interactive terminal
      id: 'cmds'          # Persistent session ID (survives lesson navigation)
      title: 'Command Line'
      allowRedirects: true
      allowCommands:       # Restrict allowed commands (optional)
        - rails
        - ruby
        - node
    - type: output         # Read-only output panel (max 1 per lesson)
      title: 'Setup Logs'
```

**Shorthand panel syntax:**

```yaml
panels:
  - terminal                    # Interactive terminal, default title
  - output                     # Read-only output, default title
  - [terminal, "Rails Console"] # Interactive with custom title
  - ['output', 'Setup Logs']   # Read-only with custom title
```

**Persistent sessions:** Use `id` to keep terminal state across lesson navigation. The user's terminal history and running processes persist when they switch between lessons that share the same `id`.

### Output Panel

Only **one** `output` panel is allowed per lesson. It captures output from `prepareCommands` and `mainCommand`.

## Preview Configuration

### Basic

```yaml
previews: false          # No preview panel
previews: true           # Auto-detect preview
previews: [3000]         # Show preview for port 3000
```

### Advanced

```yaml
previews:
  - 3000                                          # Port only
  - "3000/products"                               # Port with pathname
  - [3000, "Rails App"]                           # Port with title
  - [3000, "Rails App", "/products"]              # Port, title, pathname
  - { port: 3000, title: "App", pathname: "/products" }  # Object form
```

### Auto-Reload

```yaml
autoReload: true    # Force preview reload when navigating to this lesson
```

Useful for lessons where the preview state may be stale from a previous lesson.

## Commands

### prepareCommands

Commands that run **before** the lesson is interactive. Shown as progress steps to the user:

```yaml
prepareCommands:
  - 'npm install'                                              # String form
  - ['npm install', 'Preparing Ruby runtime']                  # [command, label]
  - { command: 'node scripts/rails.js db:prepare', title: 'Preparing database' }  # Object form
```

**Rails patterns:**

```yaml
# Basic — just install WASM runtime (set at tutorial level)
prepareCommands:
  - ['npm install', 'Preparing Ruby runtime']

# With database — for lessons that need migrations/seeds
prepareCommands:
  - ['npm install', 'Preparing Ruby runtime']
  - ['node scripts/rails.js db:prepare', 'Prepare development database']
```

### terminalBlockingPrepareCommandsCount

How many `prepareCommands` must finish before the terminal becomes interactive:

```yaml
terminalBlockingPrepareCommandsCount: 1   # Block until npm install finishes
```

### mainCommand

The primary long-running process (usually the dev server). Runs after all `prepareCommands` complete:

```yaml
mainCommand: ['node scripts/rails.js server', 'Starting Rails server']
```

**Important:** Use `node scripts/rails.js server` — not `rails server` — because the Rails CLI dispatches through Node.js wrapper scripts in this WASM environment.

## Filesystem Watching

```yaml
filesystem:
  watch: true                            # Watch all files
  watch: ['/*.json', '/workspace/**/*']  # Watch specific patterns
```

For Rails tutorials, watch `/workspace/**/*` so the preview reflects file changes in the Rails app.

## Defaults

When a property is not set at any level in the cascade, these defaults apply:

| Property | Default | Effect |
|----------|---------|--------|
| `template` | `'default'` | Uses the base Rails WASM runtime template |
| `editor` | (unset) | Editor is shown with default file tree |
| `terminal` | (unset) | One read-only "Output" panel, initially closed |
| `previews` | `true` | Auto-detect: shows preview for the first port that opens |
| `autoReload` | (unset) | Preview is not force-reloaded on navigation |
| `focus` | (unset) | No file auto-opened in editor |
| `openInStackBlitz` | `true` | "Open in StackBlitz" button shown |
| `downloadAsZip` | `false` | Download button hidden |
| `mainCommand` | (unset) | No long-running process started |
| `prepareCommands` | (unset) | No preparation steps |
| `filesystem.watch` | (unset) | No file watching |
| `scope` | (unset) | All files visible in tree |
| `hideRoot` | `true` | Root "/" node hidden in file tree |
| `custom` | (unset) | No custom fields |

## Constraints

Invalid or problematic frontmatter combinations that cause silent failures:

| Combination | Problem | Fix |
|-------------|---------|-----|
| `focus: /path/...` with `editor: false` | Focus is silently ignored — no editor to open the file in | Remove `focus` or set `editor: true` |
| `previews: [3000]` without `mainCommand` | Nothing starts a server on port 3000 — preview stays blank | Add `mainCommand: ['node scripts/rails.js server', 'Starting Rails server']` |
| `mainCommand: 'rails server'` | Bare `rails` won't work — commands must go through the Node.js wrapper | Use `mainCommand: ['node scripts/rails.js server', 'Starting Rails server']` |
| Lesson `prepareCommands` without `npm install` | WASM runtime never loads — everything else fails | Always include `['npm install', 'Preparing Ruby runtime']` as the first prepare command |
| `previews` without `prepareCommands` including `npm install` | Runtime not loaded, server can't start | Add `prepareCommands` with `npm install` (or inherit from tutorial root) |
| `terminal: false` with `mainCommand` set | Terminal hidden but `mainCommand` still runs — output is invisible | Either show terminal or remove `mainCommand` |
| `custom.shell.workdir` set only in `meta.md` | `custom` doesn't inherit — terminal won't cd in lessons | Set `custom.shell.workdir` on each lesson's `content.md` |

## Other Options

### Custom Shell Working Directory

```yaml
custom:
  shell:
    workdir: "/workspace/store"
```

Sets the terminal's working directory by sending `cd /home/tutorial<workdir> && clear` to the first terminal panel on lesson load. The path is constructed by prepending `/home/tutorial` to the `workdir` value, so `workdir: "/workspace/store"` sends `cd /home/tutorial/workspace/store && clear`. This is a **Rails-tutorial-specific** feature (implemented via `ShellConfigurator` in this template, not upstream TutorialKit). Essential for Rails tutorials where the app lives at `/workspace/<app-name>`.

**Does not inherit.** Must be set on every lesson that needs it (see Inheritance Rules above).

### Template Selection

```yaml
template: default          # Use the default (base Rails) template
template: rails-app        # Use a template with pre-generated Rails app
```

Templates live in `src/templates/`. Each lesson can also override via `_files/.tk-config.json`.

### Download and StackBlitz

```yaml
openInStackBlitz: false       # Hide "Open in StackBlitz" button (default: true)
openInStackBlitz:             # Object form with project customization
  projectTitle: "My Rails Tutorial"
  projectDescription: "A Rails CRUD app"
  projectTemplate: "node"     # html | node | angular-cli | create-react-app | javascript | polymer | typescript | vue
downloadAsZip: true           # Allow downloading lesson code (default: false)
downloadAsZip:
  filename: "rails-crud-app"  # Custom zip filename
```

### Edit Page Link

```yaml
editPageLink: "https://github.com/your-org/your-tutorial/edit/main/src/content/tutorial/${path}"
```

### Meta Tags

```yaml
meta:
  title: "Learn Rails CRUD Operations"
  description: "Build a product catalog with full CRUD in Ruby on Rails"
  image: "/og-image.png"
```

## i18n — Customize UI Text

Override any UI label at any level in the cascade:

```yaml
i18n:
  solveButtonText: "Show Answer"
  resetButtonText: "Start Over"
  prepareEnvironmentTitleText: "Setting Up Rails"
  toggleTerminalButtonText: "Terminal"
  defaultPreviewTitleText: "Rails App"
  startWebContainerText: "Launch Tutorial"
```

All available keys:

| Key | Default |
|-----|---------|
| `partTemplate` | `"Part ${index}: ${title}"` |
| `editPageText` | `"Edit this page"` |
| `webcontainerLinkText` | `"Powered by WebContainers"` |
| `startWebContainerText` | `"Run this tutorial"` |
| `noPreviewNorStepsText` | `"No preview to run nor steps to show"` |
| `filesTitleText` | `"Files"` |
| `fileTreeCreateFileText` | `"Create file"` |
| `fileTreeCreateFolderText` | `"Create folder"` |
| `fileTreeActionNotAllowedText` | `"This action is not allowed"` |
| `fileTreeFileExistsAlreadyText` | `"File exists on filesystem already"` |
| `fileTreeAllowedPatternsText` | `"Created files and folders must match following patterns:"` |
| `confirmationText` | `"OK"` |
| `prepareEnvironmentTitleText` | `"Preparing Environment"` |
| `defaultPreviewTitleText` | `"Preview"` |
| `reloadPreviewTitle` | `"Reload Preview"` |
| `toggleTerminalButtonText` | `"Toggle Terminal"` |
| `solveButtonText` | `"Solve"` |
| `resetButtonText` | `"Reset"` |
