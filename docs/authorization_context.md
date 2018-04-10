# Authorization Context

_Authorization context_ contains information about the acting subject.

In most cases, it's just a _user_, but sometimes it could be a composition of subjects.

You must configure authorization context in **two places**: in the policy itself and in the place where you perform authorization (e.g., controllers).

By default, `ActionPolicy::Base` includes `user` as authorization context. If you don't need it, you have to [build your base policy](custom_policy.md) yourself.

To specify additional contexts, you should use `authorize` method:

```ruby
class ApplicationPolicy < ActionPolicy::Base
  authorize :account
end
```

Now you must provide `account` during policy initialization. When authorization key is missing or equals to `nil`, `ActionPolicy::AuthorizationContextMissing` error is raised.

**NOTE:** if you want to allow passing `nil` as `account` value, you must add `allow_nil: true` option to `authorize`.

To do that automatically in your `authorize!` and `allowed_to?` calls you must also configure authorization context. For example, in your controller:

```ruby
class ApplicationController < ActionController::Base
  # First argument should be the same as in the policy.
  # `through` specifies the method name to be called to
  # get the required context object
  # (equals to the context name itself by default, i.e. `account`)
  authorize :account, through: :current_account
end
```
