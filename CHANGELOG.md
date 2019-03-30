## master

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

- Fix railtie initialisation for Rails < 5. ([@brendon][])

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
[@korolvs]: https://github.com/korolvs
