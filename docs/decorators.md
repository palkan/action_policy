# Dealing with Decorators

Ref: [action_policy#7](https://github.com/palkan/action_policy/issues/7).

Since Action Policy [lookup mechanism](./lookup_chain.md) relies on the target
record's class properties (names, methods) it could break when using with _decorators_.

To make `authorize!` and other [behaviour](./behaviour.md) methods work seamlessly with decorated
objects, you might want to _enhance_ the `policy_for` method.

For example, when using the [Draper](https://github.com/drapergem/draper) gem:

```ruby
module ActionPolicy
  module Draper
    def policy_for(record:, **opts)
      # From https://github.com/GoodMeasuresLLC/draper-cancancan/blob/master/lib/draper/cancancan.rb
      record = record.model while record.is_a?(::Draper::Decorator)
      super(record: record, **opts)
    end
  end
end

class ApplicationController < ActionController::Base
  prepend ActionPolicy::Draper
end
```
