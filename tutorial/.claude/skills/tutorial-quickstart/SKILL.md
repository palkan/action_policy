---
name: tutorial-quickstart
description: |
  Use this skill whenever starting a new tutorial project, understanding the end-to-end
  workflow from scaffold to deployment, or working with the rails-app template's built-in
  features. Trigger when the user says 'new tutorial', 'create tutorial', 'getting started',
  'npx create-tutorialkit-rb', 'scaffold', 'first lesson', 'deploy tutorial', 'build:wasm',
  'COEP headers', 'COOP headers', 'hosting setup', 'CSS classes', 'BEM components',
  'design system', 'application.css', 'quick login', 'preauthenticate', 'authentication
  setup', 'customize demo app', 'seed users', 'rails-app template', 'branding', 'logo',
  'favicon', 'accent color', 'theme color', 'look and feel', 'customize colors', or asks
  how to set up, build, style, brand, or deploy a Rails tutorial from scratch — even if
  they don't explicitly mention quickstart. This skill provides the exact CLI commands,
  project structure, WASM build steps, rails-app template features (CSS design system,
  authentication, quick login), branding customization (logos, favicons, accent colors,
  top bar title, component colors), demo app customization steps, deployment header
  configuration, and common issue troubleshooting. Do NOT attempt project setup or deployment without this skill. Do NOT
  use for detailed frontmatter reference (use tutorial-lesson-config) or WASM compatibility
  questions (use rails-wasm-author-constraints).
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
        │           └── app/
        │               └── controllers/
        │                   └── pages_controller.rb
        └── _solution/                   ← Solution code
            └── workspace/
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
focus: /workspace/app/controllers/pages_controller.rb
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
# _files/workspace/app/controllers/pages_controller.rb
class PagesController < ApplicationController
  # Add your action here
end
```

### 4e. Add Solution Files

Put the completed code in `_solution/`:

```ruby
# _solution/workspace/app/controllers/pages_controller.rb
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

## The `rails-app` Template

The scaffold includes a pre-built `rails-app` template at `src/templates/rails-app/` with authentication, styling, and seed data ready to go. Most tutorials should extend this template rather than building from scratch.

### What's Included

- **Authentication** — session-based login via `Authentication` concern (`app/controllers/concerns/authentication.rb`)
- **Quick login** — password-free login buttons on the sign-in page for tutorial convenience
- **CSS design system** — modern BEM-based stylesheet with CSS custom properties
- **Seed users** — Alice and Bob created in `db/seeds.rb`
- **Layout** — nav bar with brand, user name, login/logout; flash messages; `.container` wrapper

### Authentication Flow

The template uses Rails 8's authentication generator pattern:

- `Authentication` concern adds `require_authentication` as a `before_action`
- Controllers opt out with `allow_unauthenticated_access`
- `Current.user` is available everywhere via `Current.session.user`
- `authenticated?` helper works in both controllers and views

**Quick login** lets tutorial users sign in with one click instead of typing credentials:

- `SessionsController#new` populates `@preauthenticate_users` (all users by default)
- `SessionsController#preauthenticate` logs in by user ID (no password)
- The `sessions/_preauthenticate_user.html.erb` partial renders each quick-login button
- Route: `post :preauthenticate, on: :collection` under `resource :session`

To customize quick-login users in a lesson, override the sessions controller in `_files/`:

```ruby
# _files/workspace/app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create preauthenticate]

  def new
    # Show only specific users for this lesson
    @preauthenticate_users = User.where(role: "agent").order(:name)
  end
  # ... rest inherited from template
end
```

### CSS Design System

The template's `application.css` uses pure CSS with custom properties and BEM naming. Use these classes in your lesson ERB files — no extra setup needed.

**CSS Custom Properties (`:root` variables):**

| Category | Variables | Example |
|----------|-----------|---------|
| Colors | `--color-primary`, `--color-danger`, `--color-success`, `--color-warning`, `--color-info` | `color: var(--color-primary)` |
| Text | `--color-text`, `--color-text-muted`, `--color-text-inverse` | `color: var(--color-text-muted)` |
| Background | `--color-bg`, `--color-bg-white`, `--color-border` | `background: var(--color-bg)` |
| Spacing | `--space-xs` through `--space-2xl` | `padding: var(--space-md)` |
| Typography | `--font-sans`, `--font-mono`, `--font-size-sm` through `--font-size-3xl` | `font-size: var(--font-size-lg)` |
| Radius | `--radius-sm` through `--radius-xl` | `border-radius: var(--radius-md)` |
| Shadows | `--shadow-sm`, `--shadow-md` | `box-shadow: var(--shadow-sm)` |

**BEM Components:**

| Component | Classes | Usage |
|-----------|---------|-------|
| Button | `.btn`, `.btn--primary`, `.btn--danger`, `.btn--small`, `.btn--link` | Links, submits, actions |
| Input | `.input`, `.input--error` | Text fields, selects, textareas |
| Card | `.card`, `.card__header`, `.card__body`, `.card__footer` | Content containers |
| Alert | `.alert`, `.alert--error`, `.alert--success`, `.alert--info`, `.alert--warning` | Flash messages, notices |
| Badge | `.badge`, `.badge--primary`, `.badge--success`, `.badge--danger`, `.badge--warning` | Status labels, role tags |
| Nav | `.nav`, `.nav__brand`, `.nav__link`, `.nav__user` | Top navigation (in layout) |
| Form | `.form__group`, `.form__label`, `.form__hint`, `.form__errors`, `.form__actions` | Form layout |
| Table | `.table` | Data tables with hover rows |
| Page header | `.page-header` | Title + action button row |
| Hero | `.hero`, `.hero__title`, `.hero__subtitle`, `.hero__actions` | Landing/home pages |
| Quick login | `.quick-login`, `.quick-login__btn`, `.quick-login__name`, `.quick-login__email` | Sign-in page |
| Utility | `.text-muted`, `.text-sm`, `.mt-md`, `.mb-md`, `.inline-actions`, `.container` | Spacing, text helpers |

### Customizing the Demo App for Your Domain

To turn the generic demo app into your tutorial's domain (e.g., a Help Desk, a Store, etc.):

**1. Rename the app module** in `config/application.rb`:

```ruby
module Helpdesk  # was DemoApp
  class Application < Rails::Application
```

**2. Add your models.** Create migrations in `db/migrate/` and models in `app/models/`. Update `db/schema.rb` to match.

**3. Add controllers and views.** Put CRUD controllers in `app/controllers/` and ERB views in `app/views/`. Use the BEM classes from the CSS design system.

**4. Update routes** in `config/routes.rb`.

**5. Update seeds** in `db/seeds.rb` with domain-specific sample data. Keep the default password `s3cr3t` for all users so the quick-login flow works.

**6. Update the layout** — change the brand name in `app/views/layouts/application.html.erb`, add nav links for your resources.

**7. Update the home page** — replace the hero content in `app/views/home/index.html.erb`.

## Step 5: Use a Template for Pre-Built State

If your lesson needs an existing Rails app (not just an empty workspace), create a template:

```
src/templates/my-app/
├── .tk-config.json          → { "extends": "../default" }
└── workspace/
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

## Customizing Look & Feel (Branding)

To match your tutorial's branding to your project's documentation site, update these files:

### Logos

Replace `public/logo.svg` (light mode) and `public/logo-dark.svg` (dark mode) with your project's logo SVG. Use a dark fill (e.g., `#0F4D8A`) for the light-mode version and a light fill (e.g., `#E4E6E9`) for the dark-mode version.

### Title in Top Bar

Edit `src/components/TopBar.astro` — add a `<span>` after the logo images inside the `<a>` tag:

```html
<span class="ml-2 text-sm font-medium text-tk-elements-topBar-iconButton-iconColor whitespace-nowrap">
  Your Tutorial Title
</span>
```

### Favicon

Replace `public/favicon.svg` with your project's icon. Optionally add a `public/favicon.ico` for broader browser support.

### Accent Colors (UnoCSS Theme)

Override the `accent` palette in `uno.config.ts` to change buttons, links, active tabs, and badges site-wide:

```ts
import { defineConfig } from '@tutorialkit-rb/theme';

export default defineConfig({
  theme: {
    colors: {
      accent: {
        50: '#EFF6FF',
        100: '#E5F0FF',
        200: '#B6D4FF',
        300: '#75B5FF',
        400: '#4DA6FF',   // dark mode accent
        500: '#0E7EF1',   // primary interactive
        600: '#0F4D8A',   // primary brand
        700: '#0C3F72',
        800: '#09325A',
        900: '#072848',
        950: '#041A30',
      },
    },
  },
  content: {
    pipeline: { include: '**' },
  },
});
```

Generate your scale from your brand's primary color. The `600` slot is the main brand color; `500` is for hover/interactive states; `400` is used in dark mode.

### Component Hardcoded Colors

Some components use hardcoded Tailwind color classes instead of theme tokens. Search for and replace these:

- **`src/components/HelpDropdown.tsx`** — Reload button uses `bg-blue-600`. Change to `bg-accent-600 hover:bg-accent-700`.
- **`src/components/HeadTags.astro`** — Rails path link colors. Update hex values to match your brand.

### Rails Demo App CSS

Update the primary color in `src/templates/rails-app/workspace/app/assets/stylesheets/application.css`:

```css
:root {
  --color-primary: #0F4D8A;       /* your brand color */
  --color-primary-hover: #0C3F72; /* darker shade */
  --color-primary-light: #EFF6FF; /* tinted background */
}
```

### GitHub Link

Update the repo URL in `src/components/GitHubLink.astro`:

```html
<a href="https://github.com/your-org/your-repo" ...>
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
