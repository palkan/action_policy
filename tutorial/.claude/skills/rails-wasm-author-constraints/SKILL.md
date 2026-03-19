---
name: rails-wasm-author-constraints
description: |
  Use this skill whenever checking if a Rails feature or gem works in WASM, or understanding
  what's real vs. conceptual in lessons. Trigger on: 'does X work in WASM', 'can I use this
  gem', 'gem compatibility', 'WASM limitation', 'what works', 'supported features', 'PGLite',
  'threading', 'Net::HTTP', 'ActionCable', 'background jobs', 'can I teach X', 'bundle
  install in WASM', 'conceptual vs real', or any Rails capability question — even without
  mentioning WASM. Authoritative compatibility matrix: which features work, which are shimmed,
  which are impossible, plus gem tiers, PGLite behavior, boot timing, and conceptual-vs-real
  operations. General Rails knowledge is insufficient here. Do NOT use for file organization
  (use rails-file-management) or frontmatter (use tutorial-lesson-config).
---

# Rails WASM Author Constraints

What works, what doesn't, and how to design lessons around the WASM environment.

## Quick Reference: What Can I Teach?

| Rails Feature | Works? | Notes |
|---------------|--------|-------|
| ActiveRecord (CRUD, queries, scopes) | Yes | Full support via PGLite |
| Migrations & schema management | Yes | Standard `rails db:migrate` |
| Controllers & routing | Yes | Full support |
| Views (ERB templates) | Yes | Full support |
| Form helpers & validations | Yes | Full support |
| Model associations | Yes | `has_many`, `belongs_to`, etc. |
| Scaffolding & generators | Yes | `rails generate scaffold`, etc. |
| Asset pipeline (Propshaft) | Yes | Importmaps, Stimulus, Turbo |
| Rails console | Yes | Interactive IRB via custom bridge |
| Authentication (basic) | Yes | `has_secure_password`, session-based |
| ActionMailer (define mailers) | Partial | Can define/configure but delivery is a no-op |
| Active Storage (upload) | Partial | Upload works but image processing is a no-op |
| Background jobs | No | Single-threaded; Solid Queue won't process |
| ActionCable / WebSockets | No | No `IO.select`, no real socket support |
| External HTTP requests | No | No outbound networking from Ruby — sockets are unimplemented at the WASI level |
| Threads / parallel processing | No | `Thread.new` uses fibers (cooperative, single-threaded) |
| System commands from Ruby | No | `system()`, backticks, `Open3` are non-functional |

## Hard Limitations

These are **impossible to work around** in the WASM environment. Do not write lessons that depend on them:

### No Outbound Networking

Socket operations (`TCPSocket`, `UDPSocket`, and all socket classes) fail because the underlying WASI syscalls are unimplemented. `Net::HTTP` and `open-uri` will raise errors when attempting connections. You cannot:
- Call external APIs from Ruby
- Download files from the internet
- Connect to external databases or services

**Workaround for lessons:** If you want to teach API consumption, focus on the controller/model patterns and mock the responses. Show the code structure without executing real HTTP calls.

### No Process Spawning

`system()`, backticks, `exec`, `fork`, and `Open3` are non-functional. The `rails new` generator works because it's been patched, but arbitrary shell commands from tutorial code will not work.

### No Threading

`Thread.new` is shimmed to use `Fiber.new` (cooperative, single-threaded). Code that relies on parallel execution behaves differently. Background job processing and concurrent operations don't work as expected.

### No IO.select

The `poll_oneoff` WASI syscall is unimplemented. This breaks gems like nio4r, Puma, and ActionCable's EventMachine adapter.

### No chmod/fchmod

POSIX permission calls are stubbed. Avoid `FileUtils.chmod` in tutorial code. The `rails new` generator is pre-patched to handle this.

## Gem Compatibility

### Adding Gems

Authors **can add gems** to their tutorial by editing `ruby-wasm/Gemfile` and running `bin/build-wasm` to rebuild the WASM binary. This bakes all gems into the binary at build time.

### Compatibility Tiers

| Tier | Description | Examples |
|------|-------------|---------|
| **Works** | Pure Ruby gems, no native extensions | `devise`, `friendly_id`, `pagy`, `pundit`, `draper`, `kaminari` |
| **Shimmed** | Has native extensions but already patched | `nokogiri` (stub), `io-console` (stub), `bcrypt` |
| **Needs testing** | May work if extension compiles for WASM | Test with `bin/build-wasm` |
| **Won't work** | Requires unsupported syscalls or networking | `pg` (native), `mysql2`, `redis`, `sidekiq`, `puma` |

### Pre-Shimmed Gems

These gems are already handled by the WASM runtime:

| Gem | Behavior |
|-----|----------|
| `nokogiri` | 165-line minimal stub; CSS selectors return `[]`; sufficient for sanitization but not real HTML parsing |
| `io-console` | Stubbed; `winsize` returns `[80, 24]`; `raw` yields without change |
| `nio4r` | `.so` stripped; loads as empty shim |
| `date`, `psych`, `bigdecimal` | `.so` stripped; Ruby falls back to pure-Ruby stdlib |
| `sqlite3` (native) | Replaced by PGLite adapter |

### Gem Build Workflow

```bash
# 1. Edit the Gemfile
vim ruby-wasm/Gemfile

# 2. Rebuild the WASM binary (takes several minutes)
bin/build-wasm

# 3. Test your tutorial locally
npm run dev
```

## Database: PGLite

The database is **PGLite** — an in-browser PostgreSQL implementation compiled to WASM.

### What Works

- Standard ActiveRecord operations: `create`, `find`, `where`, `update`, `destroy`
- Migrations: `rails db:migrate`, `rails db:rollback`
- Seeds: `rails db:seed`
- PostgreSQL-compatible SQL syntax
- Multiple databases (development, test)
- Associations, joins, aggregations
- Indexes and constraints

### What to Know

| Behavior | Detail |
|----------|--------|
| **Data does not survive page reloads** | WebContainer filesystem is in-memory; refreshing the browser resets everything |
| **Database adapter** | `pglite` (auto-configured by wasmify-rails; authors don't need to set this up) |
| **Setup command** | `node scripts/rails.js db:prepare` in `prepareCommands` |
| **Location** | `pgdata/<dbname>/` in WebContainer filesystem |
| **Performance** | Slower than native PostgreSQL; acceptable for tutorial-sized datasets |

### Lesson Design Implications

- Always include `['node scripts/rails.js db:prepare', 'Prepare development database']` in `prepareCommands` for lessons that use the database
- Provide seeds in templates so users start with data
- Don't rely on data from a previous lesson persisting — each lesson should set up its own state via migrations + seeds

## Boot Timing

The WASM runtime takes time to load. Set expectations for tutorial users:

| Phase | Typical Duration | What Happens |
|-------|-----------------|--------------|
| `npm install` | 10-30s | Downloads ~80MB WASM binary + dependencies |
| WASM compile | 2-5s | Browser compiles the binary |
| Rails bootstrap | 2-5s | Loads Rails framework from embedded VFS |
| Command execution | Varies | User's command runs |

**Total first-load time: 15-40 seconds** depending on network and browser.

### Author Tips for Boot Experience

- Include a note in early lessons: "The Ruby runtime takes a moment to load — this is normal!"
- Use `prepareCommands` with descriptive labels so users see progress
- The `['output', 'Setup Logs']` terminal panel shows boot details
- Subsequent lesson navigation is faster if the WebContainer is already booted

## Auto-Authentication

The runtime includes an auto-login patch: if `tmp/authenticated-user.txt` exists in the Rails app root, the first HTTP request auto-authenticates the user found by `User.find_by(email_address: <file contents>)`. The file should contain a single email address (e.g., `admin@example.com`).

**To use:** Place `workspace/tmp/authenticated-user.txt` in `_files/` or a template, containing the email of a seeded user. The first request calls `start_new_session_for(user)`, creating a session cookie for all subsequent requests. Runs once per VM lifetime (the `$__pre_authenticated` global flag prevents repeat attempts).

This requires the Rails 8 `Authentication` concern and a `User` model with an `email_address` column.

## Integration Testing

Rails integration tests work in the WASM runtime with important limitations.

### What Works

- `ActionDispatch::IntegrationTest` with `get`, `post`, `patch`, `delete`
- `assert_response`, `assert_redirected_to`
- `assert_difference`, `assert_no_difference`
- Fixtures (`fixtures :all`) for test data
- Cookie-based session management for authentication

### What Does NOT Work

**Nokogiri-dependent assertions are unavailable.** The Nokogiri gem is a minimal stub in WASM — CSS selectors return `[]` and HTML parsing is non-functional. This means these Rails test helpers will not work:

- `assert_select` — relies on Nokogiri CSS selectors
- `css_select` — same
- `assert_dom` — same
- Any assertion that parses response HTML into a DOM

### Best Practices

**Use `response.body` string matching instead of DOM assertions:**

```ruby
# BAD — uses Nokogiri under the hood
assert_select "h1", text: "Tickets"
assert_select ".alert--error", text: /blank/
assert_select "form"

# GOOD — plain string matching
assert_includes response.body, "Tickets"
assert_includes response.body, "blank"
assert_includes response.body, "<form"
```

**Define an `assert_text` helper in `test_helper.rb`:**

```ruby
class ActionDispatch::IntegrationTest
  def assert_text(text)
    assert_includes response.body, text
  end
end
```

**Use cookie-based sign_in without making HTTP requests:**

```ruby
class ActionDispatch::IntegrationTest
  private

  def sign_in(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies[:session_id] = cookie_jar[:session_id]
    end
  end
end
```

**Disable test parallelization** — PGLite does not support concurrent connections:

```ruby
module ActiveSupport
  class TestCase
    parallelize(workers: 1)
    fixtures :all
  end
end
```

## Filesystem Boundaries

Ruby code can only access `/workspace` (the WASI preopen). Attempting to access paths outside this boundary raises `Errno::ENOENT`. Tutorial code should never navigate above `/workspace` with `Dir.chdir("..")` or absolute paths outside the preopen.

## Conceptual vs. Real Operations

Some tutorial operations are **conceptual** — they teach the correct pattern but the actual execution requires something different in the WASM environment:

| Operation in lesson content | Reality | What the author must do |
|-----------------------------|---------|------------------------|
| "Add `gem 'devise'` to your Gemfile" | Gems are baked into the WASM binary at build time | The gem must already be in `ruby-wasm/Gemfile` and rebuilt with `bin/build-wasm` **before** the tutorial is published |
| "Run `bundle install`" | `bundle install` is a no-op in WASM — all gems come from the binary | Include it for pedagogical completeness; it will appear to succeed |
| "Run `rails server`" | The Rails server runs through `node scripts/rails.js server` | Use `node scripts/rails.js server` in frontmatter `mainCommand`; in lesson content, show `rails server` since that's what the terminal wrapper understands |
| "Edit `database.yml`" | Database adapter is PGLite, auto-configured by wasmify-rails | Pre-configure in the template; showing a `database.yml` edit is fine for teaching but won't change the runtime behavior |
