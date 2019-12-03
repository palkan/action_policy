# Writing Policies

Policy class contains predicate methods (_rules_) which are used to authorize activities.

A Policy is instantiated with the target `record` (authorization object) and the [authorization context](authorization_context.md) (by default equals to `user`):

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

## Initializing policies

**NOTE**: it is not recommended to manually initialize policy objects and use them directly (one exclusion–[tests](testing.md)). Use [`authorize!` / `allowed_to?` methods](./behaviour.md#authorize) instead.

To initialize policy object, you should specify target record and context:

```ruby
policy = PostPolicy.new(post, user: user)

# simply call rule method
policy.update?
```

You can omit the first argument (in that case `record` would be `nil`).

Instead of calling rules directly, it is better to call the `apply` method (which wraps rule method with some useful functionality, such as [caching](caching.md), [pre-checks](pre_checks.md), and [failure reasons tracking](reasons.md)):

```ruby
policy.apply(:update?)
```

## Calling other policies

Sometimes it is useful to call other resources policies from within a policy. Action Policy provides the `allowed_to?` method as a part of `ActionPolicy::Base`:

```ruby
class CommentPolicy < ApplicationPolicy
  def update?
    user.admin? || (user.id == record.id) ||
      allowed_to?(:update?, record.post)
  end
end
```

You can also specify all the usual options (such as `with`).

There is also a `check?` method which is just an "alias"\* for `allowed_to?` added for better readability:

```ruby
class PostPolicy < ApplicationPolicy
  def show?
    user.admin? || check?(:publicly_visible?)
  end

  def publicly_visible?
    # ...
  end
end
```

\* It's not a Ruby _alias_ but a wrapper; we can't use `alias` or `alias_method`, 'cause `allowed_to?` could be extended by some extensions.

## Identifiers

Each policy class has an `identifier`, which is by default just an underscored class name:

```ruby
class CommentPolicy < ApplicationPolicy
end

CommentPolicy.identifier #=> :comment
```

For namespaced policies it has a form of:

```ruby
module ActiveAdmin
  class UserPolicy < ApplicationPolicy
  end
end

ActiveAdmin::UserPolicy.identifier # => :"active_admin/user"
```

You can specify your own identifier:

```ruby
module MyVeryLong
  class LongLongNamePolicy < ApplicationPolicy
    self.identifier = :long_name
  end
end

MyVeryLong::LongLongNamePolicy.identifier #=> :long_name
```

Identifiers are required for some modules, such as [failure reasons tracking](reasons.md) and [i18n](i18n.md).
