# Change log

## master

## 0.7.1 (2024-07-25)

- Support passing scope options to callable scope objects. ([@palkan][])

## 0.7.0 (2024-06-20)

- **Ruby 2.7+** is required.

- Support using callable objects as scopes. ([@killondark][])

## 0.6.9 (2024-04-19)

- Add `.with_context` modifier to the `#have_authorized_scope` matcher. ([@killondark][])

## 0.6.8 (2024-01-17)

- Do not preload Rails base classes, use load hooks everywhere. ([@palkan][])

## 0.6.7 (2023-09-13)

- Fix loading Rails extensions during eager load. ([@palkan][])

## 0.6.6 (2023-09-11)

- Fix loading Active Record and Action Controller scope matchers. ([@palkan][])

- Add `--parent` option for policy generator ([@matsales28][])

Example:

`bin/rails g action_policy:policy user --parent=base_policy` generates:

```ruby
class UserPolicy < BasePolicy
# ...
end
```

## 0.6.5 (2023-02-16)

- Fix generated policies' outdated Ruby API (to work with Ruby 3.2).

## 0.6.4 (2022-01-17)

- Fix loading of Rails scope matchers. ([@palkan][])

[Issue #225](https://github.com/palkan/action_policy/issues/225)

- Add support to assert context in test matchers ([@matsales28][])

## 0.6.3 (2022-08-16)

- Fix regression for [#179](https://github.com/palkan/action_policy/issues/179). ([@palkan][])

## 0.6.2 (2022-08-12)

- Allow omitting authorization record if `with` is provided. ([@palkan][])

## 0.6.1 (2022-05-23)

- Fix policy lookup when a namespaced record is passed and the strict mode is used. ([@palkan][])
- Expose `#authorized_scope` as helper. ([@palkan][])
- [Fixes [#207](https://github.com/palkan/action_policy/issues/207)] refinement#include deprecation warning on Ruby 3.1

## 0.6.0 (2021-09-02)

- Drop Ruby 2.5 support.
- [Closes [#186](https://github.com/palkan/action_policy/issues/186)] Add `inline_reasons: true` option to `allowed_to?` to avoid wrapping reasons. ([@palkan][])
- [Fixes [#173](https://github.com/palkan/action_policy/issues/173)] Explicit context were not merged with implicit one within policy classes. ([@palkan][])
- Add `strict_namespace:` option to policy_for behaviour ([@kevynlebouille][])
- Prevent possible side effects in policy lookup ([@tomdalling][])

## 0.5.7 (2021-03-03)

The previous release had incorrect dependencies (due to the missing transpiled files).

## ~~0.5.6 (2021-03-03)~~

- Add `ActionPolicy.enforce_predicate_rules_naming` config to catch rule missing question mark ([@skojin][])

## 0.5.5 (2020-12-28)

- Upgrade to Ruby 3.0. ([@palkan][])

## 0.5.4 (2020-12-09)

- Add support for RSpec aliases detection when linting policy specs with `rubocop-rspec` 2.0 ([@pirj][])

- Fix `strict_namespace: true` lookup option not finding policies in global namespace ([@Be-ngt-oH][])

## 0.5.0 (2020-09-29)

- Move `deny!` / `allow!` to core. ([@palkan][])

Now you can call `deny!` and `allow!` in policy rules to fail- or pass-fast.

**BREAKING.** Pre-check name is no longer added automatically to failure reasons. You should specify the reason
explicitly: `deny!(:my_reason)`.

- Add `Result#all_details` to return all collected details in a single hash. ([@palkan][])

- Add `default` option to lookup and `default_authorization_policy_class` callback to behaviour. ([@palkan][])

- Add `skip_verify_authorized!` to Rails controllers integration. ([@palkan][])

This method allows you to skip the `verify_authorized` callback dynamically.

- **Drop Ruby 2.4 support**. ([@palkan][])

- Add `allowance_to` method to authorization behaviour. ([@palkan][])

This method is similar to `allowed_to?` but returns an authorization result object.

- Support aliases in `allowed_to?` / `check?` calls within policies. ([@palkan][])

## 0.4.5 (2020-07-29)

- Add strict_namespace option to lookup chain. (@rainerborene)

## 0.4.4 (2020-07-07)

- Fix symbol lookup with namespaces. ([@palkan][])

Fixes [#122](https://github.com/palkan/action_policy/issues/122).

- Separated `#classify`-based and `#camelize`-based symbol lookups. ([@Be-ngt-oH][])

Only affects Rails apps. Now lookup for `:users` tries to find `UsersPolicy` first (camelize),
and only then search for `UserPolicy` (classify).

See [PR#118](https://github.com/palkan/action_policy/pull/118).

- Fix calling rules with `allowed_to?` directly. ([@palkan][])

  Fixes [#113](https://github.com/palkan/action_policy/issues/113)

## 0.4.3 (2019-12-14)

- Add `#cache(*parts, **options) { ... }` method. ([@palkan][])

Allows you to cache anything in policy classes using the Action Policy
cache key generation mechanism.

- Handle versioned Rails cache keys. ([@palkan][])

Use `#cache_with_version` as a cache key if defined.

## 0.4.2 (2019-12-13)

- Fix regression introduced in 0.4.0 which broke testing Class targets. ([@palkan][])

## 0.4.0 (2019-12-11)

- Add `action_policy.init` instrumentation event. ([@palkan][])

Triggered every time a new policy object is initialized.

- Fix policy memoization with explicit context. ([@palkan][])

Explicit context (`authorize! context: {}`) wasn't considered during
policies memoization. Not this is fixed.

- Support composed matchers for authorization target testing. ([@palkan][])

Now you can write tests like this:

```ruby
expect { subject }.to be_authorized_to(:show?, an_instance_of(User))
```

## 0.3.4 (2019-11-27)

- Fix Rails generators. ([@palkan][])

Only invoke install generator if `application_policy.rb` is missing.
Fix hooking into test frameworks.

## 0.3.3 (2019-11-27)

- Improve pretty print functionality. ([@palkan][])

Colorize true/false values.
Handle multiline expressions and debug statements (i.e., `binding.pry`).

- Add Rails generators. ([@nicolas-brousse][])

Adds `action_policy:install` and `action_policy:policy MODEL` Rails generators.

- Optional authorization target. ([@somenugget][])

Allows making authorization context optional:

```ruby
class OptionalRolePolicy < ActionPolicy::Base
  authorize :role, optional: true
end

policy = OptionalRolePolicy.new
policy.role #=> nil
```

## 0.3.2 (2019-05-26) 👶

- Fixed thread-safety issues with scoping configs. ([@palkan][])

Fixes [#75](https://github.com/palkan/action_policy/issues/75).

## 0.3.1 (2019-05-30)

- Fixed bug with missing implicit target and hash like scoping data. ([@palkan][])

Fixes [#70](https://github.com/palkan/action_policy/issues/70).

## 0.3.0 (2019-04-02)

- Added ActiveSupport-based instrumentation. ([@palkan][])

See [PR#4](https://github.com/palkan/action_policy/pull/4)

- Allow passing authorization context explicitly. ([@palkan][])

Closes [#3](https://github.com/palkan/action_policy/issues/3).

Now it's possible to override implicit authorization context
via `context` option:

```ruby
authorize! target, to: :show?, context: {user: another_user}
authorized_scope User.all, context: {user: another_user}
```

- Renamed `#authorized` to `#authorized_scope`. ([@palkan][])

**NOTE:** `#authorized` alias is also available.

- Added `Policy#pp(rule)` method to print annotated rule source code. ([@palkan][])

Example (debugging):

```ruby
def edit?
  binding.pry # rubocop:disable Lint/Debugger
  (user.name == "John") && (admin? || access_feed?)
end
```

```sh
pry> pp :edit?
MyPolicy#edit?
↳ (
    user.name == "John" #=> false
  )
  AND
  (
    admin? #=> false
    OR
    access_feed? #=> true
  )
)
```

See [PR#63](https://github.com/palkan/action_policy/pull/63)

- Added ability to provide additional failure reasons details. ([@palkan][])

Example:

```ruby
class ApplicantPolicy < ApplicationPolicy
  def show?
    allowed_to?(:show?, object.stage)
  end
end

class StagePolicy < ApplicationPolicy
  def show?
    # Add stage title to the failure reason (if any)
    # (could be used by client to show more descriptive message)
    details[:title] = record.title
    # then perform the checks
    user.stages.where(id: record.id).exists?
  end
end

# when accessing the reasons
p ex.result.reasons.details #=> { stage: [{show?: {title: "Onboarding"}] }
```

See https://github.com/palkan/action_policy/pull/58

- Ruby 2.4+ is required. ([@palkan][])

- Added RSpec DSL for writing policy specs. ([@palkan])

The goal of this DSL is to reduce the boilerplate when writing
policies specs.

Example:

```ruby
describe PostPolicy do
  let(:user) { build_stubbed :user }
  let(:record) { build_stubbed :post, draft: false }

  let(:context) { {user: user} }

  describe_rule :show? do
    succeed "when post is published"

    failed "when post is draft" do
      before { post.draft = false }

      succeed "when user is a manager" do
        before { user.role = "manager" }
      end
    end
  end
end
```

- Added I18n support ([@DmitryTsepelev][])

Example:

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActionPolicy::Unauthorized do |ex|
    p ex.result.message #=> "You do not have access to the stage"
    p ex.result.reasons.full_messages #=> ["You do not have access to the stage"]
  end
end
```

- Added scope options to scopes. ([@korolvs][])

See [#47](https://github.com/palkan/action_policy/pull/47).

Example:

```ruby
# users_controller.rb
class UsersController < ApplicationController
  def index
    @user = authorized(User.all, scope_options: {with_deleted: true})
  end
end

# user_policy.rb
describe UserPolicy < Application do
  relation_scope do |relation, with_deleted: false|
    rel = some_logic(relation)
    with_deleted ? rel.with_deleted : rel
  end
end
```

- Added Symbol lookup to the lookup chain ([@DmitryTsepelev][])

For instance, lookup will implicitly use `AdminPolicy` in a following case:

```ruby
# admin_controller.rb
class AdminController < ApplicationController
  authorize! :admin, to: :update_settings
end
```

- Added testing for scopes. ([@palkan][])

Example:

```ruby
# users_controller.rb
class UsersController < ApplicationController
  def index
    @user = authorized(User.all)
  end
end

# users_controller_spec.rb
describe UsersController do
  subject { get :index }
  it "has authorized scope" do
    expect { subject }.to have_authorized_scope(:active_record_relation)
      .with(PostPolicy)
  end
end
```

- Added scoping support. ([@palkan][])

See [#5](https://github.com/palkan/action_policy/issues/5).

By "scoping" we mean an ability to use policies to _scope data_.

For example, when you want to _scope_ Active Record collections depending
on the current user permissions:

```ruby
class PostsController < ApplicationController
  def index
    @posts = authorized(Post.all)
  end
end

class PostPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if user.admin?
    relation.where(user: user)
  end
end
```

Action Policy provides a flexible mechanism to apply scopes to anything you want.

Read more in [docs](https://actionpolicy.evilmartians.io/).

- Added `#implicit_authorization_target`. ([@palkan][]).

See [#35](https://github.com/palkan/action_policy/issues/35).

Implicit authorization target (defined by `implicit_authorization_target`) is used when no target specified for `authorize!` call.

For example, for Rails controllers integration it's just `controller_name.classify.safe_constantize`.

- Consider `record#policy_name` when looking up for a policy class. ([@palkan][])

## 0.2.4 (2018-09-06)

- [Fix [#39](https://github.com/palkan/action_policy/issues/39)] Fix configuring cache store in Rails. ([@palkan][])

- Add `did_you_mean` suggestion to `UnknownRule` exception. ([@palkan][])

- Add `check?` as an alias for `allowed_to?` in policies. ([@palkan][])

- Add ability to disable per-thread cache and disable it in test env by default. ([@palkan][])

You can control per-thread cache by setting:

```ruby
ActionPolicy::PerThreadCache.enabled = true # or false
```

## 0.2.3 (2018-07-03)

- [Fix [#16](https://github.com/palkan/action_policy/issues/16)] Add ability to disable namespace resolution cache. ([@palkan][])

We cache namespaced policy resolution for better performance (it could affect performance when we look up a policy from a deeply nested module context).

It could be disabled by setting `ActionPolicy::LookupChain.namespace_cache_enabled = false`. It's enabled by default unless `RACK_ENV` env var is specified and is not equal to `"production"` (e.g. when `RACK_ENV=test` the cache is disabled).

When using Rails it's enabled only in production mode but could be configured through setting the `config.action_policy.namespace_cache_enabled` parameter.

- [Fix [#18](https://github.com/palkan/action_policy/issues/18)] Clarify documentation around, and fix the way `resolve_rule` resolves rules and rule aliases when subclasses are involved. ([@brendon][])

## 0.2.2 (2018-07-01)

- [Fix [#29](https://github.com/palkan/action_policy/issues/29)] Fix loading cache middleware. ([@palkan][])

- Use `send` instead of `public_send` to get the `authorization_context` so that contexts such as
  `current_user` can be `private` in the controller. ([@brendon][])

- Fix railtie initialization for Rails < 5. ([@brendon][])

## 0.2.1 (yanked)

## 0.2.0 (2018-06-17)

- Make `action_policy` JRuby-compatible. ([@palkan][])

- Add `reasons.details`. ([@palkan][])

```ruby
rescue_from ActionPolicy::Unauthorized do |ex|
  ex.result.reasons.details #=> { stage: [:show?] }
end
```

- Add `ExecutionResult`. ([@palkan][])

ExecutionResult contains all the rule application artifacts: the result (`true` / `false`),
failures reasons.

This value is now stored in a cache (if any) instead of just the call result (`true` / `false`).

- Add `Policy.identifier`. ([@palkan][])

## 0.1.4 (2018-06-06)

- Fix Railtie injection hook. ([@palkan][])

- Fix Ruby 2.3 compatibility. ([@palkan])

## 0.1.3 (2018-05-20)

- Fix modules order in `ActionPolicy::Base`. ([@ilyasgaraev][])

## 0.1.2 (2018-05-09)

- [Fix [#6](https://github.com/palkan/action_policy/issues/6)] Fix controller concern to work with API/Metal controllers. ([@palkan][])

## 0.1.1 (2018-04-21)

- [Fix [#2](https://github.com/palkan/action_policy/issues/2)] Fix namespace lookup when Rails autoloading is involved. ([@palkan][])

## 0.1.0 (2018-04-17)

- Initial pre-release version. ([@palkan][])

[@palkan]: https://github.com/palkan
[@ilyasgaraev]: https://github.com/ilyasgaraev
[@brendon]: https://github.com/brendon
[@DmitryTsepelev]: https://github.com/DmitryTsepelev
[@korolvs]: https://github.com/slavadev
[@nicolas-brousse]: https://github.com/nicolas-brousse
[@somenugget]: https://github.com/somenugget
[@Be-ngt-oH]: https://github.com/Be-ngt-oH
[@pirj]: https://github.com/pirj
[@skojin]: https://github.com/skojin
[@tomdalling]: https://github.com/tomdalling
[@matsales28]: https://github.com/matsales28
[@killondark]: https://github.com/killondark
