# Using with Rails

Action Policy seamlessly integrates with Ruby on Rails applications.

In most cases, you do not have to do anything except writing policy files and adding `authorize!` calls.

**NOTE:** both controllers and channels extensions are built on top of the Action Policy [behaviour](./behaviour.md) mixin.

## Generators

Action Policy provides a couple of useful Rails generators:

- `rails g action_policy:install` — adds `app/policies/application_policy.rb` file
- `rails g action_policy:policy MODEL_NAME` — adds a policy file and a policy test file for a given model (also creates an `application_policy.rb` if it's missing)
- `rails g action_policy:policy MODEL_NAME --parent=base_policy` — adds a policy file that inherits from `BasePolicy`, and a policy test file for a given model (also creates an `application_policy.rb` if it's missing)

## Controllers integration

Action Policy assumes that you have a `current_user` method which specifies the current authenticated subject (`user`).

You can turn off this behaviour by setting `config.action_policy.controller_authorize_current_user = false` in `application.rb`, or override it:

```ruby
class ApplicationController < ActionController::Base
  authorize :user, through: :my_current_user
end
```

You can also pass a proc to `:through`. This is useful if you're using `ActiveSupport::CurrentAttributes`:

```ruby
class ApplicationController < ActionController::Base
  authorize :user, through: -> { Current.user }
end
```

**NOTE:** The `controller_authorize_current_user` setting only affects the way authorization context is built in controllers but does not affect policy classes configuration. If you inherit from `ActionPolicy::Base`, you will still have the `user` required as an authorization context. Add `authorize :user, optional: true` to your base policy class to make it optional or use a [custom base class](custom_policy.md).

> Read more about [authorization context](authorization_context.md).

If you don't want to include Action Policy in your controllers at all,
you can disable the integration by setting `config.action_policy.auto_inject_into_controller = false` in `application.rb`.

### `verify_authorized` hooks

Usually, you need all of your actions to be authorized. Action Policy provides a controller hook which ensures that an `authorize!` call has been made during the action:

```ruby
class ApplicationController < ActionController::Base
  # adds an after_action callback to verify
  # that `authorize!` has been called.
  verify_authorized

  # you can also pass additional options,
  # like with a usual callback
  verify_authorized except: :index
end
```

You can skip this check when necessary:

```ruby
class PostsController < ApplicationController
  skip_verify_authorized only: :show

  def index
    # or dynamically within an action
    skip_verify_authorized! if some_condition
  end
end
```

When an unauthorized action is encountered, the `ActionPolicy::UnauthorizedAction` error is raised.

### Resource-less `authorize!`

You can also call `authorize!` without a resource specified.
In that case, Action Policy tries to infer the resource class from the controller name:

```ruby
class PostsController < ApplicationController
  def index
    # Uses Post class as a resource implicitly.
    # NOTE: it just calls `controller_name.classify.safe_constantize`,
    # you can override this by defining `implicit_authorization_target` method.
    authorize!
  end
end
```

### Usage with `API` and `Metal` controllers

Action Policy is only included into `ActionController::Base`. If you want to use it with other base Rails controllers, you have to include it manually:

```ruby
class ApiController < ActionController::API
  include ActionPolicy::Controller

  # NOTE: you have to provide authorization context manually as well
  authorize :user, through: :current_user
end
```

## Channels integration

Action Policy also integrates with Action Cable to help you authorize your channels actions:

```ruby
class ChatChannel < ApplicationCable::Channel
  def follow(data)
    chat = Chat.find(data["chat_id"])

    # Verify against ChatPolicy#show? rule
    authorize! chat, to: :show?
    stream_from chat
  end
end
```

Action Policy assumes that you have `current_user` as a connection identifier.

You can turn off this behaviour by setting `config.action_policy.channel_authorize_current_user = false` in `application.rb`, or override it:

```ruby
module ApplicationCable
  class Channel < ActionCable::Channel::Base
    # assuming that identifier is called `user`
    authorize :user
  end
end
```

> Read more about [authorization context](authorization_context.md).

In case you do not want to include Action Policy to channels at all,
you can disable the integration by setting `config.action_policy.auto_inject_into_channel = false` in `application.rb`.
