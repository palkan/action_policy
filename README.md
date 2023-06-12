[![Gem Version](https://badge.fury.io/rb/action_policy.svg)](https://badge.fury.io/rb/action_policy)
![Build](https://github.com/palkan/action_policy/workflows/Build/badge.svg)
![JRuby Build](https://github.com/palkan/action_policy/workflows/JRuby%20Build/badge.svg)
[![Documentation](https://img.shields.io/badge/docs-link-brightgreen.svg)](https://actionpolicy.evilmartians.io)
[![Coverage Status](https://coveralls.io/repos/github/palkan/action_policy/badge.svg)](https://coveralls.io/github/palkan/action_policy)

# Action Policy

<img align="right" height="150" width="129"
     title="Action Policy logo" src="./docs/assets/images/logo.svg">

Authorization framework for Ruby and Rails applications.

Composable. Extensible. Performant.

📑 [Documentation](https://actionpolicy.evilmartians.io)

<a href="https://evilmartians.com/?utm_source=action_policy">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Resources

- RubyRussia, 2019 "Welcome, or access denied?" talk ([video](https://www.youtube.com/watch?v=y15a2g7v8i0) [RU], [slides](https://speakerdeck.com/palkan/rubyrussia-2019-welcome-or-access-denied))

- Seattle.rb, 2019 "A Denial!" talk ([slides](https://speakerdeck.com/palkan/seattle-dot-rb-2019-a-denial))

- RailsConf, 2018 "Access Denied" talk ([video](https://www.youtube.com/watch?v=NVwx0DARDis), [slides](https://speakerdeck.com/palkan/railsconf-2018-access-denied-the-missing-guide-to-authorization-in-rails))

## Integrations

- GraphQL Ruby ([`action_policy-graphql`](https://github.com/palkan/action_policy-graphql))
- Graphiti (JSON:API) ([`action_policy-graphiti`](https://github.com/shrimple-tech/action_policy-graphiti))

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem "action_policy"
```

And then execute:

```sh
bundle install
```

## Usage

Action Policy relies on resource-specific policy classes (just like [Pundit](https://github.com/varvet/pundit)).

First, add an application-specific `ApplicationPolicy` with some global configuration to inherit from:

```ruby
class ApplicationPolicy < ActionPolicy::Base
end
```

This may be done with `rails generate action_policy:install` generator.

Then write a policy for a resource. For example:

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

This may be done with `rails generate action_policy:policy Post` generator.
You can also use `rails generate action_policy:policy Post --parent=BasePolicy` to make the generated policy inherits
from `BasePolicy`.

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

\* See [Non-Rails Usage](docs/non_rails.md) on how to add `authorize!` to any Ruby project.

When authorization is successful (i.e., the corresponding rule returns `true`), nothing happens, but in case of authorization failure `ActionPolicy::Unauthorized` error is raised.

There is also an `allowed_to?` method which returns `true` or `false`, and could be used, in views, for example:

```erb
<% @posts.each do |post| %>
  <li><%= post.title %>
    <% if allowed_to?(:edit?, post) %>
      <%= link_to post, "Edit">
    <% end %>
  </li>
<% end %>
```

Read more in our [Documentation][].

## Alternatives

There are [many authorization libraries](https://www.ruby-toolbox.com/categories/rails_authorization) for Ruby/Rails applications.

What makes Action Policy different? See [this section](https://actionpolicy.evilmartians.io/#/?id=what-about-the-existing-solutions) in our docs.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/action_policy.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[Documentation]: http://actionpolicy.evilmartians.io
