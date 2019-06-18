# Custom Base Policy

`ActionPolicy::Base` is a combination of all available policy extensions with the default configuration.

It looks like this:


```ruby
class ActionPolicy::Base
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Authorization
  include ActionPolicy::Policy::PreCheck
  include ActionPolicy::Policy::Reasons
  include ActionPolicy::Policy::Aliases
  include ActionPolicy::Policy::Scoping
  include ActionPolicy::Policy::Cache
  include ActionPolicy::Policy::CachedApply
  include ActionPolicy::Policy::Defaults

  # ActionPolicy::Policy::Defaults module adds the following

  authorize :user

  default_rule :manage?
  alias_rule :new?, to: :create?

  def index?
    false
  end

  def create?
    false
  end

  def manage?
    false
  end
end
```



You can write your `ApplicationPolicy` from scratch instead of inheriting from `ActionPolicy::Base`
if the defaults above do not fit your needs. The only required component is `ActionPolicy::Policy::Core`:

```ruby
# minimal ApplicationPolicy
class ApplicationPolicy
  include ActionPolicy::Policy::Core
end
```

The `Core` module provides `apply` and `allowed_to?` methods.
