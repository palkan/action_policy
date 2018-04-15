# Pre-Checks

Consider a typical situation when you start most—or even all—of your rules with the same predicates.

For example, when you have a super-user role in the application:

```ruby
class PostPolicy < ApplicationPolicy
  def show?
    user.super_admin? || record.published
  end

  def update?
    user.super_admin? || (user.id == record.user_id)
  end

  # more rules
end
```

Action Policy allows you to extract the common parts from rules into _pre-checks_:

```ruby
class PostPolicy < ApplicationPolicy
  pre_check :allow_admins

  def show?
    record.published
  end

  def update?
    user.id == record.user_id
  end

  private

  def allow_admins
    allow! if user.super_admin?
  end
end
```

Pre-checks act like _callbacks_: you can add multiple pre-checks, specify `except` and `only` options, and skip already defined pre-checks if necessary:

```ruby
class UserPolicy < ApplicationPolicy
  skip_pre_check :allow_admins, only: :destroy?

  def destroy?
    user.admin? && !record.admin?
  end
end
```

To halt the authorization process within a pre-check, you must return either `allow!` or `deny!` call value. When any other value is returned, the pre-check is ignored, and the rule is called (or next pre-check).

**NOTE**: pre-checks are available only if you inherit from `ActionPolicy::Base` or include `ActionPolicy::Policy::PreCheck` into your `ApplicationPolicy`.
