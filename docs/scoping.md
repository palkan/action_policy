# Scoping

By _scoping_ we mean an ability to use policies to _scope data_ (or _filter/modify/transform/choose-your-verb_).

The most common situation is when you want to _scope_ ActiveRecord relations depending
on the current user permissions. Without policies it could look like this:

```ruby
class PostsController < ApplicationController
  def index
    @posts =
      if current_user.admin?
        Post.all
      else
        Post.where(user: current_user)
      end
  end
end
```

That's a very simplified example. In practice scoping rules might be more complex, and it's likely that we would use them in multiple places.

Action Policy allows you to define scoping rules within a policy class and use them with the help of `authorized` method:

```ruby
class PostsController < ApplicationController
  def index
    @posts = authorized(Post.all)
  end
end

class PostPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if user.admin?
    relation.where(user: user)
  end
end
```

## Define scopes

To define scope you should use either `scope_for` or `smth_scope` methods in your policy:

```ruby
class PostPolicy < ApplicationPolicy
  # define a scope of a `relation` type
  scope_for :relation do |relation|
    relation.where(user: user)
  end

  # define a scope of `my_data` type,
  # which acts on hashes
  scope_for :my_data do |data|
    next data if user.admin?
    data.delete_if { |k, _| SENSITIVE_KEYS.include?(k) }
  end
end
```

Scopes have _types_: different types of scopes are meant to be applied to different data types.

You can specify multiple scopes (_named scopes_) for the same type providing a scope name:

```ruby
class EventPolicy < ApplictionPolicy
  scope_for :relation, :own do |relation|
    relation.where(owner: user)
  end
end
```

When the second argument is not speficied, the `:default` is implied as the scope name.

## Apply scopes

Action Policy behaviour (`ActionPolicy::Behaviour`) provides an `authorized` method which allows you to use scoping:

```ruby
class PostsController < ApplicationController
  def index
    # The first argument is the target,
    # which is passed to the scope block
    #
    # The second argument is the scope type
    @posts = authorized(Post.all, :relation)
    #
    # For named scopes provide `as` option
    @events = authorized(Event.all, :relation, as: :own)
  end
end
```

You can also specify additional options for policy class inference (see [behaviour docs](./behaviour.md)). For example, to explicitly specify the policy class use:

```ruby
@posts = authorized(Post.all, with: CustomPostPolicy)
```

## Scope type inference

TBD

## Rails integration

Action Policy provides a couple of _scope matchers_ out-of-the-box for ActiveRecord relations and ActionController paramters.

### ActiveRecord scopes

Scope type `:relation` is automatically applied to the object of `ActiveRecord::Relation` type.

To define ActiveRecord scopes you can use `relation_scope` macro (which is just an alias for `scope :relation`) in your policy:

```ruby
class PostPolicy < ApplicationPolicy
  # Equals `scope_for :relation do ...`
  relation_scope do |scope|
    if super_user? || admin?
      scope
    else
      scope.joins(:accesses).where(accesses: { user_id: user.id })
    end
  end

  # define named scope
  relation_scope(:own) do |scope|
    next scope.none if user.guest?
    scope.where(user: user)
  end
end
```

**NOTE:** the `:relation` scoping is used if and only if an `ActiveRecord::Relation` is passed to `authorized`:

```ruby
def index
  # BAD: Post is not a relation; raises an exception
  @posts = authorized(Post)

  # GOOD:
  @posts = authorized(Post.all)
end
```

### ActionController parameters

Use scopes of type `:params` if your strong parameters filterings depend on the current user:

```ruby
class UserPolicy < ApplicationPolicy
  # Equals to `scope_for :params do ...`
  params_scope do |params|
    if user.admin?
      params.permit(:name, :email, :role)
    else
      params.permit(:name)
    end
  end
end

class UsersController < ApplicationController
  def create
    # Call `authorized` on `params` object
    @user = User.create!(authorized(params.require(:user)))
    head :ok
  end
end
```
