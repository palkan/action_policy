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
  default_rule :manage?

  def manage?
    # ...
  end
end
```

Now when you call `authorize! post` with any rule not explicitly defined in policy class, the `manage?` rule is applied.

By default, `ActionPolicy::Base` sets `manage?` as a default rule.
