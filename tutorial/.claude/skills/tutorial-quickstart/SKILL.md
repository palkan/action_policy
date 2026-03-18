---
name: tutorial-quickstart
description: |
  Use this skill whenever starting a new tutorial project or understanding the end-to-end
  workflow from scaffold to deployment. Trigger when the user says 'new tutorial', 'create
  tutorial', 'getting started', 'npx create-tutorialkit-rb', 'scaffold', 'first lesson',
  'deploy tutorial', 'build:wasm', 'COEP headers', 'COOP headers', 'hosting setup', or
  asks how to set up, build, or deploy a Rails tutorial from scratch — even if they don't
  explicitly mention quickstart. This skill provides the exact CLI commands, project structure,
  WASM build steps, deployment header configuration, and common issue troubleshooting
  specific to this project. Do NOT attempt project setup or deployment without this skill.
  Do NOT use for detailed frontmatter reference (use tutorial-lesson-config) or WASM
  compatibility questions (use rails-wasm-author-constraints).
---

# Tutorial Quickstart

End-to-end guide: scaffold a project, write your first lesson, and deploy.

## Step 1: Scaffold

```bash
npx create-tutorialkit-rb my-tutorial
```

The CLI prompts for:

| Prompt | Default | Notes |
|--------|---------|-------|
| Tutorial name | random (e.g., "fierce-turtle") | Used as `package.json` name |
| Directory | `./{name}` | Where files are created |
| Hosting provider | Skip | Vercel, Netlify, or Cloudflare — adds COEP/COOP headers |
| Package manager | npm | npm, yarn, pnpm, or bun |
| Init git repo? | Yes | Creates initial commit |
| Edit Gemfile? | Yes | Opens `ruby-wasm/Gemfile` in `$EDITOR` |

Skip all prompts with `--defaults`, or pass flags directly:

```bash
npx create-tutorialkit-rb my-tutorial -p pnpm --provider netlify --git
```

### What Gets Created

```
my-tutorial/
├── src/
│   ├── content/tutorial/        ← Your tutorial content goes here
│   │   ├── meta.md              ← Tutorial root config (already set up)
│   │   └── 1-getting-started/   ← Sample part with starter lessons
│   ├── templates/default/       ← WebContainer runtime (don't modify)
│   └── components/              ← UI components
├── ruby-wasm/
│   └── Gemfile                  ← Add gems here, then rebuild WASM
├── bin/build-wasm               ← Rebuilds the WASM binary
├── astro.config.ts
└── package.json
```

## Step 2: Add Your Gems

Edit `ruby-wasm/Gemfile` to include the gems your tutorial needs:

```ruby
# ruby-wasm/Gemfile
source "https://rubygems.org"

gem "wasmify-rails", "~> 0.4.0"
gem "rails", "~> 8.0.0"

# Your tutorial's gems
gem "action_policy"
gem "devise"
```

Then build the WASM binary:

```bash
npm run build:wasm    # Takes up to 20 minutes on first run
```

Subsequent rebuilds are faster thanks to caching, but still take a few minutes.

## Step 3: Start the Dev Server

```bash
npm run dev           # Starts at http://localhost:4321/
```

The sample tutorial loads immediately. You'll see the starter lessons from the scaffold.

## Step 4: Write Your First Lesson

### 4a. Create the Directory Structure

```
src/content/tutorial/
├── meta.md                              ← Already exists (tutorial root)
└── 1-basics/
    ├── meta.md                          ← Part metadata
    └── 1-hello-rails/
        ├── content.md                   ← Your lesson
        ├── _files/                      ← Starting code
        │   └── workspace/
        │       └── store/
        │           └── app/
        │               └── controllers/
        │                   └── pages_controller.rb
        └── _solution/                   ← Solution code
            └── workspace/
                └── store/
                    └── app/
                        └── controllers/
                            └── pages_controller.rb
```

### 4b. Write the Part Metadata

```yaml
# src/content/tutorial/1-basics/meta.md
---
type: part
title: The Basics
---
```

### 4c. Write the Lesson

```yaml
# src/content/tutorial/1-basics/1-hello-rails/content.md
---
type: lesson
title: Hello Rails
focus: /workspace/store/app/controllers/pages_controller.rb
previews: [3000]
mainCommand: ['node scripts/rails.js server', 'Starting Rails server']
prepareCommands:
  - ['npm install', 'Preparing Ruby runtime']
  - ['node scripts/rails.js db:prepare', 'Prepare development database']
custom:
  shell:
    workdir: '/workspace/store'
---

# Hello Rails

Open `app/controllers/pages_controller.rb` and add a `home` action:

\`\`\`ruby title="app/controllers/pages_controller.rb" ins={2-4}
class PagesController < ApplicationController
  def home
    render plain: "Hello from Rails on WebAssembly!"
  end
end
\`\`\`

Visit the preview to see your message.
```

### 4d. Add Starting Files

Put a skeleton file in `_files/`:

```ruby
# _files/workspace/store/app/controllers/pages_controller.rb
class PagesController < ApplicationController
  # Add your action here
end
```

### 4e. Add Solution Files

Put the completed code in `_solution/`:

```ruby
# _solution/workspace/store/app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
    render plain: "Hello from Rails on WebAssembly!"
  end
end
```

### 4f. Delete the Sample Content

Remove the scaffold's starter lessons once you have your own:

```bash
rm -rf src/content/tutorial/1-getting-started/
rm -rf src/content/tutorial/2-controllers/
```

## Step 5: Use a Template for Pre-Built State

If your lesson needs an existing Rails app (not just an empty workspace), create a template:

```
src/templates/my-app/
├── .tk-config.json          → { "extends": "../default" }
└── workspace/
    └── store/
        ├── app/
        ├── config/
        ├── db/
        └── ...
```

Then reference it from your lesson's `_files/.tk-config.json`:

```json
{
  "extends": "../../../../../templates/my-app"
}
```

See the `rails-file-management` skill for details on template inheritance.

## Step 6: Deploy

Tutorials need **Cross-Origin-Embedder-Policy** and **Cross-Origin-Opener-Policy** headers for WebContainers to work. If you chose a hosting provider during scaffold, these are already configured.

### Build for Production

```bash
npm run build         # Produces a static site in dist/
```

### Manual Header Configuration

If you didn't choose a provider during scaffold, add these headers to every response:

```
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Opener-Policy: same-origin
```

#### Vercel (`vercel.json`)

```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "Cross-Origin-Embedder-Policy", "value": "require-corp" },
        { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" }
      ]
    }
  ]
}
```

#### Netlify (`netlify.toml`)

```toml
[[headers]]
for = "/*"
[headers.values]
Cross-Origin-Embedder-Policy = "require-corp"
Cross-Origin-Opener-Policy = "same-origin"
```

#### Cloudflare (`public/_headers`)

```
/*
  Cross-Origin-Embedder-Policy: require-corp
  Cross-Origin-Opener-Policy: same-origin
```

## Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| `build:wasm` fails | Missing WASI SDK or build tools | Check `rbwasm` prerequisites |
| Preview shows nothing | Server not started | Add `mainCommand: ['node scripts/rails.js server', ...]` |
| Terminal stuck on "Preparing" | WASM binary not built | Run `npm run build:wasm` first |
| Files not appearing in editor | Wrong path | All Rails files must be under `workspace/<app>/` |
| Database empty | No `db:prepare` in prepareCommands | Add `['node scripts/rails.js db:prepare', '...']` |
| Deploy fails with blank page | Missing COEP/COOP headers | Add headers per provider instructions above |

## Next Steps

| Want to... | See skill |
|------------|-----------|
| Structure parts, chapters, lessons | `tutorial-content-structure` |
| Configure frontmatter options | `tutorial-lesson-config` |
| Organize Rails files properly | `rails-file-management` |
| Check if a feature works in WASM | `rails-wasm-author-constraints` |
| Get a recipe for a specific lesson type | `rails-lesson-recipes` |
