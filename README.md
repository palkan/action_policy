[![Gem Version](https://badge.fury.io/rb/action_policy.svg)](https://badge.fury.io/rb/action_policy)
[![Build Status](https://travis-ci.org/palkan/action_policy.svg?branch=master)](https://travis-ci.org/palkan/action_policy)
[![Documentation](https://img.shields.io/badge/docs-link-brightgreen.svg)](http://palkan.github.io/action_policy)

# ActionPolicy

Action Policy is an authorization framework for Ruby and Rails applications.

📑 [Documentation][]

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Installation

Add this line to your application's Gemfile:

```ruby
gem "action_policy"
```

And then execute:

    $ bundle

## Usage

Action Policy relies on resource-specific policy classes (just like [Pundit](https://github.com/varvet/pundit)).

First, add an application-specific `ApplicationPolicy` with some global configuration to inherit from:

```ruby
class ApplicationPolicy < ActionPolicy::Base
end
```

Then write a policy for some resource. For example:

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

\* See [Non-Rails Usage](docs/non_rails.md) on how to add `authorize!` to any Ruby project


When authorization is successful (i.e. the corresponding rule returns `true`) nothing happens, but in case of authorization failure `ActionPolicy::Unauthorized` error is raised.

There is also an `allowed_to?` method which returns `true` of `false` and could be used, for example, in views:

```erb
<% @posts.each do |post| %>
  <li><%= post.title %>
    <% if allowed_to?(:edit?, post) %>
      = link_to post, "Edit"
    <% end %>
  </li>
<% end %>
```

Read more in our [Documentation][].

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/action_policy.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[Documentation]: http://palkan.github.io/action_policy