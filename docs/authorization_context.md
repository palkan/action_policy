# Authorization Context

_Authorization context_ contains information about the acting subject.

In most cases, it is just a _user_, but sometimes it could be a composition of subjects.

You must configure authorization context in **two places**: in the policy itself and in the place where you perform the authorization (e.g., controllers).

By default, `ActionPolicy::Base` includes `user` as authorization context. If you don't need it, you have to [build your own base policy](custom_policy.md).

To specify additional contexts, you should use the `authorize` method:

```ruby
class ApplicationPolicy < ActionPolicy::Base
  authorize :account
end
```

Now you must provide `account` during policy initialization. When authorization key is missing or equals to `nil`, `ActionPolicy::AuthorizationContextMissing` error is raised.

**NOTE:** if you want to allow passing `nil` as `account` value, you must add `allow_nil: true` option to `authorize`.
If you want to be able not to pass `account` at all, you must add `optional: true`

To do that automatically in your `authorize!` and `allowed_to?` calls, you must also configure authorization context. For example, in your controller:

```ruby
class ApplicationController < ActionController::Base
  # First argument should be the same as in the policy.
  # `through` specifies the method name to be called to
  # get the required context object
  # (equals to the context name itself by default, i.e. `account`)
  authorize :account, through: :current_account
end
```

## Nested Policies vs Contexts

See also: [action_policy#36](https://github.com/palkan/action_policy/issues/36) and [action_policy#37](https://github.com/palkan/action_policy/pull/37)

When you call another policy from the policy object (e.g. via `allowed_to?` method),
the context of the current policy is passed to the _nested_ policy.

That means that if the nested policy has a different authorization context, we won't be able
to build it (event if you configure all the required keys in the controller).

For example:

```ruby
class UserPolicy < ActionPolicy::Base
  authorize :user

  def show?
    allowed_to?(:show?, record.profile)
  end
end

class ProfilePolicy < ActionPolicy::Base
  authorize :user, :account
end

class ApplicationController < ActionController::Base
  authorize :user, through: :current_user
  authorize :account, through: :current_account
end

class UsersController < ApplicationController
  def show
    user = User.find(params[:id])

    authorize! user #=> raises "Missing policy authorization context: account"
  end
end
```

That means that **all the policies that could be used together MUST share the same set of authorization contexts** (or at least the _parent_ policies contexts must be subsets of the nested policies contexts).


## Explicit context

You can override the _implicit_ authorization context (generated with `authorize` method) in-place
by passing the `context` option:

```ruby
def show
  user = User.find(params[:id])

  authorize! user, context: {account: user.account}
end
```

**NOTE:** the explictly provided context is merged with the implicit one (i.e. you can specify
only the keys you want to override).
