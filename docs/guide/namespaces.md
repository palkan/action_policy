# Namespaces

Action Policy can lookup policies with respect to the current execution _namespace_ (i.e., authorization class module).

Consider an example:

```ruby
module Admin
  class UsersController < ApplicationController
    def index
      # uses Admin::UserPolicy if any, otherwise fallbacks to UserPolicy
      authorize!
    end
  end
end
```

Module nesting is also supported:

```ruby
module Admin
  module Client
    class UsersController < ApplicationController
      def index
        # lookup for Admin::Client::UserPolicy -> Admin::UserPolicy -> UserPolicy
        authorize!
      end
    end
  end
end
```

**NOTE**: to support namespaced lookup for non-inferrable resources,
you should specify `policy_name` at a class level (instead of `policy_class`, which doesn't take namespaces into account):

```ruby
class Guest < User
  def self.policy_name
    "UserPolicy"
  end
end
```

**NOTE**: by default, we use class's name as a policy name; so, for namespaced resources, the namespace part is also included:

```ruby
class Admin
  class User
  end
end

# search for Admin::UserPolicy, but not for UserPolicy
authorize! Admin::User.new
```

You can access the current authorization namespace through `authorization_namespace` method.

You can also define your own namespacing logic by overriding `authorization_namespace`:

```ruby
def authorization_namespace
  return ::Admin if current_user.admin?
  return ::Staff if current_user.staff?
  # fallback to current namespace
  super
end
```

**NOTE**: namespace support is an extension for `ActionPolicy::Behaviour` and could be included with `ActionPolicy::Behaviours::Namespaced` (included into Rails controllers and channel integrations by default).

## Namespace resolution cache

We cache namespaced policy resolution for better performance (it could affect performance when we look up a policy from a deeply nested module context, see the [benchmark](https://github.com/palkan/action_policy/blob/master/benchmarks/namespaced_lookup_cache.rb)).

It could be disabled by setting `ActionPolicy::LookupChain.namespace_cache_enabled = false`. It's enabled by default unless `RACK_ENV` env var is specified and is not equal to `"production"` (e.g. when `RACK_ENV=test` the cache is disabled).

When using Rails it's enabled only in production mode but could be configured through setting the `config.action_policy.namespace_cache_enabled` parameter.
