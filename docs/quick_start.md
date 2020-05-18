# Quick Start

## Installation

Install Action Policy with RubyGems:

```ruby
gem install action_policy
```

Or add `action_policy` to your application's `Gemfile`:

```ruby
gem "action_policy"
```

And then execute:

    $ bundle

## Basic usage

The core component of Action Policy is a _policy class_. Policy class describes how you control access to resources.

We suggest having a separate policy class for each resource and encourage you to follow these conventions:
- put policies into the `app/policies` folder (when using with Rails);
- name policies using the corresponding singular resource name (model name) with a `Policy` suffix, e.g. `Post -> PostPolicy`;
- name rules using a predicate form of the corresponding activity (typically, a controller's action), e.g. `PostsController#update -> PostPolicy#update?`.

We also recommend to use an application-specific `ApplicationPolicy` with a global configuration to inherit from:

```ruby
class ApplicationPolicy < ActionPolicy::Base
end
```

You could use the following command to generate it when using Rails:

```sh
rails generate action_policy:install
```

**NOTE:** it is not necessary to inherit from `ActionPolicy::Base`; instead, you can [construct basic policy](custom_policy.md) choosing only the components you need.

Rules must be public methods on the class. Using private methods as rules will raise an error.

Consider a simple example:

```ruby
class PostPolicy < ApplicationPolicy
  # everyone can see any post
  def show?
    true
  end

  def update?
    # `user` is a performing subject,
    # `record` is a target object (post we want to update)
    user.admin? || (user.id == record.user_id)
  end
end
```

Now you can easily add authorization to your Rails\* controller:

```ruby
class PostsController < ApplicationController
  def update
    @post = Post.find(params[:id])
    authorize! @post

    if @post.update(post_params)
      redirect_to @post
    else
      render :edit
    end
  end
end
```

\* See [Non-Rails Usage](non_rails.md) on how to add `authorize!` to any Ruby project.

In the above case, Action Policy automatically infers a policy class and a rule to verify access: `@post -> Post -> PostPolicy`, rule is inferred from the action name (`update -> update?`), and `current_user` is used as `user` within the policy by default (read more about [authorization context](authorization_context.md)).

When authorization is successful (i.e., the corresponding rule returns `true`), nothing happens, but in case of an authorization failure `ActionPolicy::Unauthorized` error is raised:

```ruby
rescue_from ActionPolicy::Unauthorized do |ex|
  # Exception object contains the following information
  ex.policy #=> policy class, e.g. UserPolicy
  ex.rule #=> applied rule, e.g. :show?
end
```

There is also an `allowed_to?` method which returns `true` or `false` and could be used, for example, in views:

```erb
<% @posts.each do |post| %>
  <li><%= post.title %>
    <% if allowed_to?(:edit?, post) %>
      <%= link_to "Edit", post %>
    <% end %>
  </li>
<% end %>
```

Although Action Policy tries to [infer the corresponding policy class](policy_lookup.md) and rule itself, there could be a situation when you want to specify those values explicitly:

```ruby
# specify the rule to verify access
authorize! @post, to: :update?

# specify policy class
authorize! @post, with: CustomPostPolicy

# or
allowed_to? :edit?, @post, with: CustomPostPolicy
```
