# Migrate from Pundit to Action Policy

Migration from Pundit to Action Policy could be done in a progressive way: first, we make Pundit polices and authorization helpers use Action Policy under the hood, then you can rewrite policies in the Action Policy way.

### Phase 1. Quacking like a Pundit.

#### Step 1. Prepare controllers.

- Remove `include Pundit` from ApplicationController

- Add `authorize` method:

```ruby
def authorize(record, rule = nil)
  options = {}
  options[:to] = rule unless rule.nil?

  authorize! record, **options
end
```

- Configure [authorization context](authorization_context) if necessary, e.g. add `authorize :current_user, as: :user` to `ApplicationController` (**NOTE:** added automatically in Rails apps)

- Add `policy` and `policy_scope` helpers:

```ruby
helper_method :policy
helper_method :policy_scope

def policy(record)
  policy_for(record)
end

def policy_scope(scope)
  authorized scope
end

```

**NOTE**: `policy` defined above is not equal to `allowed_to?` since it doesn't take into account pre-checks.

#### Step 2. Prepare policies.

We assume that you have a base class for all your policies, e.g. `ApplicationPolicy`.

Then do the following:
- Add `include ActionPolicy::Policy::Core` to `ApplicationPolicy`

- Update `ApplicationPolicy#initialize`:

```ruby
def initialize(target, user:)
  # ...
end
```

- [Rewrite scopes](scoping).

Unfortunately, there is no easy way to migrate Pundit class-based scope to Action Policies scopes.

#### Step 3. Replace RSpec helper:

We provide a Pundit-compatibile syntax for RSpec tests:

```
# Remove DSL
# require "pundit/rspec"
#
# Add Action Policy Pundit DSL
require "action_policy/rspec/pundit_syntax"
```

### Phase 2. No more Pundit.

When everything is green, it's time to fully migrate to ActionPolicy:
- make ApplicationPolicy inherit from `ActionPolicy::Base`
- migrate view helpers (from `policy(..)` to `allowed_to?`, from `policy_scope` to `authorized`)
- re-write specs using simple non-DSL syntax (or [Action Policy RSpec syntax](testing#rspec-dsl))
- add [authorization tests](testing#testing-authorization) (add `require 'action_policy/rspec'`)
- use [Reasons](reasons), [I18n integration](i18n), [cache](caching) and other Action Policy features!
