# Writing Policies

Policy class contains predicate methods (_rules_) which are used to authorize activities.

Policy instance is instantiated with the target `record` (authorization object) and the [authorization context](authorization_context.md) (by default equals to `user`):

```ruby
class PostPolicy < ActionPolicy::Base
  def index?
    # allow everyone to perform "index" activity on posts
    true
  end

  def update?
    # here we can access our context and record
    user.admin? || (user.id == record.user_id)
  end
end
```

## Manually initializing policies

**NOTE**: it is not recommended to manually initialize policy objects and use them directly (one exclusion–[tests](testing.md)). Use `authorize!` / `allowed_to?` methods instead.

To initialize policy object, you should specify target record and context:

```ruby
policy = PostPolicy.new(post, user: user)

# simply call rule method
policy.update?
```

You can omit the first argument (in that case `record` would be `nil`).

Instead of calling rules directly you'd better call `apply` method (which wraps rule method with some useful functionality, such as [caching](caching.md), [pre-checks](pre_checks.md), [failure reasons tracking](reasons.md)):

```ruby
policy.apply(:update?)
```

## Calling other policies

Sometimes it's useful to call other resources policies from within policy. Action Policy provides the `allowed_to?` method as a part of `ActionPolicy::Base`:

```ruby
class CommentPolicy < ApplicationPolicy
  def update?
    user.admin? || (user.id == record.id) ||
      allowed_to?(:update?, record.post)
  end
end
```

You can also specify all the usual options (such as `with`).
