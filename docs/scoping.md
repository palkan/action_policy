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

Action Policy allows you to define scoping rules within a policy class and use them with the help of `authorized_scope` method (`authorized` alias is also available):

```ruby
class PostsController < ApplicationController
  def index
    @posts = authorized_scope(Post.all)
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

When the second argument is not specified, the `:default` is implied as the scope name.

Also, there are cases where it might be easier to add options to existing scope than create a new one.

For example, if you use soft-deletion and your logic inside a scope depends on if deleted records are included, you can add `with_deleted` option:

```ruby
class PostPolicy < ApplicationPolicy
  scope_for :relation do |relation, with_deleted: false|
    rel = some_logic(relation)
    with_deleted ? rel.with_deleted : rel
  end
end
```

You can add as many options as you want:

```ruby
class PostPolicy < ApplicationPolicy
  scope_for :relation do |relation, with_deleted: false, magic_number: 42, some_required_option:|
    # Your code
  end
end
```
## Apply scopes

Action Policy behaviour (`ActionPolicy::Behaviour`) provides an `authorized` method which allows you to use scoping:

```ruby
class PostsController < ApplicationController
  def index
    # The first argument is the target,
    # which is passed to the scope block
    #
    # The second argument is the scope type
    @posts = authorized_scope(Post, type: :relation)
    #
    # For named scopes provide `as` option
    @events = authorized_scope(Event, type: :relation, as: :own)
    #
    # If you want to specify scope options provide `scope_options` option
    @events = authorized_scope(Event, type: :relation, scope_options: {with_deleted: true})
  end
end
```

You can also specify additional options for policy class inference (see [behaviour docs](behaviour)). For example, to explicitly specify the policy class use:

```ruby
@posts = authorized_scope(Post, with: CustomPostPolicy)
```

## Using scopes within policy

You can also use scopes within policy classes using the same `authorized_scope` method.
For example:

```ruby
relation_scope(:edit) do |scope|
  teachers = authorized_scope(Teacher.all, as: :edit)
  scope
    .joins(:teachers)
    .where(teacher_id: teachers)
end
```

## Using scopes explicitly

To use scopes without including Action Policy [behaviour](behaviour)
do the following:

```ruby
# initialize policy
policy = ApplicantPolicy.new(user: user)
# apply scope
policy.apply_scope(User.all, type: :relation)
```

## Scope type inference

Action Policy could look up a scope type if it's not specified and if _scope matchers_ were configured.

Scope matcher is an object that implements `#===` (_case equality_) or a Proc. You can define it within a policy class:

```ruby
class ApplicationPolicy < ActionPolicy::Base
  scope_matcher :relation, ActiveRecord::Relation

  # use Proc to handle AR models classes
  scope_matcher :relation, ->(target) { target < ActiveRecord::Base }

  scope_matcher :custom, MyCustomClass
end
```

Adding a scope matcher also adds a DSL to define scope rules (just a syntax sugar):

```ruby
class ApplicationPolicy < ActionPolicy::Base
  scope_matcher :relation, ActiveRecord::Relation

  # now you can define scope rules like this
  relation_scope { |relation| relation }
end
```

When `authorized_scope` is called without the explicit scope type, Action Policy uses matchers (in the order they're defined) to infer the type.

## Rails integration

Action Policy provides a couple of _scope matchers_ out-of-the-box for Active Record relations and Action Controller paramters.

### Active Record scopes

Scope type `:relation` is automatically applied to the object of `ActiveRecord::Relation` type.

To define Active Record scopes you can use `relation_scope` macro (which is just an alias for `scope :relation`) in your policy:

```ruby
class PostPolicy < ApplicationPolicy
  # Equals `scope_for :active_record_relation do ...`
  relation_scope do |scope|
    if super_user? || admin?
      scope
    else
      scope.joins(:accesses).where(accesses: {user_id: user.id})
    end
  end

  # define named scope
  relation_scope(:own) do |scope|
    next scope.none if user.guest?
    scope.where(user: user)
  end
end
```

**NOTE:** the `:active_record_relation` scoping is used if and only if an `ActiveRecord::Relation` is passed to `authorized`:

```ruby
def index
  # BAD: Post is not a relation; raises an exception
  @posts = authorized_scope(Post)

  # GOOD:
  @posts = authorized_scope(Post.all)
end
```

### Action Controller parameters

Use scopes of type `:params` if your strong parameters filterings depend on the current user:

```ruby
class UserPolicy < ApplicationPolicy
  # Equals to `scope_for :action_controller_params do ...`
  params_filter do |params|
    if user.admin?
      params.permit(:name, :email, :role)
    else
      params.permit(:name)
    end
  end

  params_filter(:update) do |params|
    params.permit(:name)
  end
end

class UsersController < ApplicationController
  def create
    # Call `authorized_scope` on `params` object
    @user = User.create!(authorized_scope(params.require(:user)))
    # Or you can use `authorized` alias which fits this case better
    @user = User.create!(authorized(params.require(:user)))
    head :ok
  end

  def update
    @user.update!(authorized_scope(params.require(:user), as: :update))
    head :ok
  end
end
```
