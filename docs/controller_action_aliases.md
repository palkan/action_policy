# Controller Action Aliases

**This is a feature proposed here: https://github.com/palkan/action_policy/issues/25**

If you'd like to see this feature implemented, please comment on the issue to show your support.

## Outline

Say you have abstracted your `authorize!` call to a controller superclass because your policy can
be executed without regard to the record in any of the subclass controllers:

```ruby
class AbstractController < ApplicationController
  authorize :context
  before_action :authorize_context

  def context
    # Some code to get your policy context
  end

  private

  def authorize_context
    authorize! Context
  end
end
```

Your policy might look like this:

```ruby
class ContextPolicy < ApplicationPolicy
  authorize :context

  alias_rule :index?, :show?, to: :view?
  alias_rule :new?, :create?, :update?, :destroy?, to: :edit?

  def view?
    context.has_permission_to(:view, user)
  end

  def edit?
    context.has_permission_to(:edit, user)
  end
end
```

We can safely add aliases for the common REST actions in the policy.

You may then want to include a concern in your subclass controller(s) that add extra actions to the controller.


```ruby
class ConcreteController < AbstractController
  include AdditionalFunctionalityConcern

  def index
    # Index Action
  end

  def new
    # New Action
  end

  # etc...
end
```

At this point you may be wondering how to tell your abstracted policy that these new methods map to either
the `view?` or `edit?` rule. You can currently provide the rule to execute to the `authorize!` method with
the `to:` parameter but since our call to `authorize!` is in a superclass it has no idea about our concern.
I propose the following controller method:

```ruby
alias_action(*actions, to_rule: rule)
```

Here's an example:

```ruby
module AdditionalFunctionalityConcern
  extend ActiveSupport::Concern

  included do
    alias_action [:first_action, :second_action], to_rule: :view?
    alias_action [:third_action], to_rule: :edit?
  end

  def first_action
    # First Action
  end

  def second_action
    # Second Action
  end

  def third_action
    # Third Action
  end
end
```

When `authorize!` is called in a controller, it will first check the action aliases for a corresponding
rule. If one is found, it will execute that rule instead of a rule matching the name of the current action.
The rule may point at a concrete rule in the policy, or a rule alias in the policy, it doens't matter, the
alias in the policy will be resolved like normal.

If you'd like to see this feature implemented, please show your support on the
[Github Issue](https://github.com/palkan/action_policy/issues/25).
