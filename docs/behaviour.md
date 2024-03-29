# Action Policy Behaviour

Action Policy provides a mixin called `ActionPolicy::Behaviour` which adds authorization methods to your classes.

## Usage

Let's make our custom _service_ object aware of authorization:

```ruby
class PostUpdateAction
  # First, we should include the behaviour
  include ActionPolicy::Behaviour

  # Secondly, provide authorization subject (performer)
  authorize :user

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def call(post, params)
    # Now we can use authorization methods
    authorize! post, to: :update?

    post.update!(params)
  end
end
```

`ActionPolicy::Behaviour` provides `authorize` class-level method to configure [authorization context](authorization_context.md) and the instance-level methods: `authorize!`, `allowed_to?`, `allowance_to`, and `authorized`:

### `authorize!`

This is a _guard-method_ which raises an `ActionPolicy::Unauthorized` exception
if authorization failed (i.e. policy rule returns false):

```ruby
# `to` is a name of the policy rule to apply
authorize! post, to: :update?
```

### `allowed_to?`

This is a _predicate_ version of `authorize!`: it returns true if authorization succeed and false otherwise:

```ruby
# the first argument is the rule to apply
# the second one is the target
if allowed_to?(:edit?, post)
  # ...
end
```

### `allowance_to`

This method is similar to `allowed_to?` but returns an authorization result instead. It's especially useful for APIs when you want to
return not only true or false but also, for example, [failure reasons](./reasons.md):

```ruby
result = allowance_to(:edit?, post)

{value: result.value, fullMessages: result.reasons.full_messages, details: result.reasons.details}.to_json
```

### `authorized`

See [scoping](./scoping.md) docs.

## Policy lookup

All three instance methods (`authorize!`, `allowed_to?`, `authorized`) uses the same
`policy_for` to lookup a policy class for authorization target. So, you can provide additional options to control the policy lookup process:

- Explicitly specify policy class using `with` option:

```ruby
allowed_to?(:edit?, post, with: SpecialPostPolicy)
```

- Provide a [namespace](./namespaces.md):

```ruby
# Would try to lookup Admin::PostPolicy first
authorize! post, to: :destroy?, namespace: Admin
```

- Provide a [strict_namespace lookup option](./lookup_chain.md):

```ruby
# Would not fallback lookup PostPolicy if Admin::PostPolicy doesn't exist
authorize! post, to: :destroy?, namespace: Admin, strict_namespace: true

# or by overriding a specific behavior method
def authorization_strict_namespace
  true
end
```

- Define a default policy to use in case lookup finds nothing:

```ruby
# either explicitly
authorize! post, to: :destroy?, default: GuestPolicy

# or by overriding a specific behavior method
def default_authorization_policy_class
  logged_in? ? DefaultUserPolicy : GuestPolicy
end
```

## Implicit authorization target

You can omit the authorization target for all the methods by defining an _implicit authorization target_:

```ruby
class PostActions
  include ActionPolicy::Behaviour

  authorize :user

  attr_reader :user, :post

  def initialize(user, post)
    @user = user
    @post = post
  end

  def update(params)
    # post is used here implicitly as a target
    authorize! to: :update

    post.update!(params)
  end

  def destroy
    # post is used here implicitly as a target
    authorize! to: :destroy

    post.destroy!
  end

  def implicit_authorization_target
    post
  end
end
```
