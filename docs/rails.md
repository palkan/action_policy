# Using with Rails

Action Policy seamlessly integrates Ruby on Rails applications seamlessly.

In most cases, you do not have to do anything except writing policy files and adding `authorize!` calls.

## Controllers integration

Action Policy assumes that you have a `current_user` method which specifies the current authenticated subject (`user`).

You can turn off this behaviour by setting `config.action_policy.controller_authorize_current_user = false` in `application.rb`, or override it:

```ruby
class ApplicationController < ActionController::Base
  authorize :user, through: :my_current_user
end
```

> Read more about [authorization context](authorization_context.md).

In case you don't want to include Action Policy to controllers at all,
you can turn disable the integration by setting `config.action_policy.auto_inject_into_controller = false` in `application.rb`.

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
end
```

When an unauthorized action is encountered, the `ActionPolicy::UnauthorizedAction` error is raised.

### Resource-less `authorize!`

You can also call `authorize!` without a resource specified.
In that case, Action Policy tries to infer the resource class from the controller name:

```ruby
class PostsController < ApplicationPolicy
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
class ApiController < ApplicationController::API
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
