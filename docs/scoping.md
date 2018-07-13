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

TBD

## Apply scopes

TBD

## Scope type inference

TBD

## Rails integration

Action Policy provides a couple of _scope matchers_ out-of-the-box for ActiveRecord relations and ActionController paramters.

### ActiveRecord scopes

Scope type `:relation` is automatically applied to the object of `ActiveRecord::Relation` type.

To define ActiveRecord scopes you can use `relation_scope` macro in your policy:

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

Use scopes of type `:params` if your strong parameters filterings depends on the current user:

```ruby
class UserPolicy < ApplicationPolicy
  # Equals `scope_for :params do ...`
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
