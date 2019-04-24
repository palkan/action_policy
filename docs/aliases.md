# Rule Aliases

Action Policy allows you to add rule aliases. It is useful when you rely on _implicit_ rules in controllers. For example:

```ruby
class PostsController < ApplicationController
  before_action :load_post, only: [:edit, :update, :destroy]

  private

  def load_post
    @post = Post.find(params[:id])
    # depending on action, an `edit?`, `update?` or `destroy?`
    # rule would be applied
    authorize! @post
  end
end
```

In your policy, you can create aliases to avoid duplication:

```ruby
class PostPolicy < ApplicationPolicy
  alias_rule :edit?, :destroy?, to: :update?
end
```

**NOTE**: `alias_rule` is available only if you inherit from `ActionPolicy::Base` or include `ActionPolicy::Policy::Aliases` into your `ApplicationPolicy`.

**Why not just use Ruby's `alias`?**

An alias created with `alias_rule` is resolved at _authorization time_ (during an `authorize!` or `allowed_to?` call), and it does not add an alias method to the class.

That allows us to write tests easier, as we should only test the rule, not the alias–and to leverage [caching](caching.md) better.

By default, `ActionPolicy::Base` adds one alias: `alias_rule :new?, to: :create?`.

## Default rule

You can add a _default_ rule–the rule that would be applied if the rule specified during authorization is missing (like a "wildcard" alias):

```ruby
class PostPolicy < ApplicationPolicy
  # For an ApplicationPolicy, makes :manage? match anything that is
  # not :index?, :create? or :new?
  default_rule :manage?

  # If you want manage? to catch really everything, place this alias
  #alias_rule :index?, :create?, :new?, to: :manage?
  def manage?
    # ...
  end
end
```

Now when you call `authorize! post` with any rule not defined in the policy class, the `manage?` rule is applied.  Note that `index?` `create?` and `new?` are already defined in the [superclass by default](custom_policy.md) (returning `false`) - if you want the same behaviour for *all* actions, define aliases like in the example above (commented out).

By default, `ActionPolicy::Base` sets `manage?` as a default rule.

## Aliases and Private Methods

Rules in `action_policy` can only be public methods. Trying to use a private method as a rule will raise an error. Thus, aliases can also only point to public methods.

## Rule resolution with subclasses

Here's the order in which aliases and concrete rule methods are resolved in regards to subclasses:

1. If there is a concrete rule method on the subclass, this is called, else
2. If there is a matching alias then this is called, else
  * When aliases are defined on the subclass they will overwrite matching aliases on the superclass.
3. If there is a concrete rule method on the superclass, then this is called, else
4. If there is a default rule defined, then this is called, else
5. `ActionPolicy::UnknownRule` is raised.

Here's an example with the expected results:

```ruby
class SuperPolicy < ApplicationPolicy
  default_rule :manage?

  alias_rule :update?, :destroy?, :create?, to: :edit?

  def manage?
  end

  def edit?
  end

  def index?
  end
end

class SubPolicy < AbstractPolicy
  default_rule nil

  alias_rule :index?, :update?, to: :manage?

  def create?
  end
end
```

Authorizing against the SuperPolicy:

* `update?` will resolve to `edit?`
* `destroy?` will resolve to `edit?`
* `create?` will resolve to `edit?`
* `manage?` will resolve to `manage?`
* `edit?` will resolve to `edit?`
* `index?` will resolve to `index?`
* `something?` will resolve to `manage?`

Authorizing against the SubPolicy:

* `index?` will resolve to `manage?`
* `update?` will resolve to `manage?`
* `create?` will resolve to `create?`
* `destroy?` will resolve to `edit?`
* `manage?` will resolve to `manage?`
* `edit?` will resolve to `edit?`
* `index?` will resolve to `manage?`
* `something?` will raise `ActionPolicy::UnknownRule`
