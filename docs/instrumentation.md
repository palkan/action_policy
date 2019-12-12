# Instrumentation

Action Policy integrates with [Rails instrumentation system](https://guides.rubyonrails.org/active_support_instrumentation.html), `ActiveSupport::Notifications`.

## Events

### `action_policy.apply_rule`

This event is triggered every time a policy rule is applied:
- when `authorize!` is called
- when `allowed_to?` is called within the policy or the [behaviour](behaviour)
- when `apply_rule` is called explicitly (i.e. `SomePolicy.new(record, context).apply_rule(record)`).

The event contains the following information:
- `:policy` – policy class name
- `:rule` – applied rule (String)
- `:value` – the result of the rule application (true of false)
- `:cached` – whether we hit the [cache](caching)\*.

\* This parameter tracks only the cache store usage, not memoization.

You can use this event to track your policy cache usage and also detect _slow_ checks.

Here is an example code for sending policy stats to [Librato](https://librato.com/)
using [`librato-rack`](https://github.com/librato/librato-rack):

```ruby
ActiveSupport::Notifications.subscribe("action_policy.apply_rule") do |event, started, finished, _, data|
  # Track hit and miss events separately (to display two measurements)
  measurement = "#{event}.#{(data[:cached] ? "hit" : "miss")}"
  # show ms times
  timing = ((finished - started) * 1000).to_i
  Librato.tracker.check_worker
  Librato.timing measurement, timing, percentile: [95, 99]
end
```

### `action_policy.authorize`

This event is identical to `action_policy.apply_rule` with the one difference:
**it's only triggered when `authorize!` method is called**.

The motivation behind having a separate event for this method is to monitor the number of failed
authorizations: the high number of failed authorizations usually means that we do not take
into account authorization rules in the application UI (e.g., we show a "Delete" button to the user not
permitted to do that).

The `action_policy.apply_rule` might have a large number of failures, 'cause it also tracks the usage of non-raising applications (i.e. `allowed_to?`).

### `action_policy.init`

This event is triggered every time a new policy object is initialized.

The event contains the following information:

- `:policy` – policy class name.

This event is useful if you want to track the number of initialized policies per _action_ (for example, when you want to ensure that
the [memoization](caching.md) works as expected).

## Turn off instrumentation

Instrumentation is enabled by default. To turn it off add to your configuration:

```ruby
config.action_policy.instrumentation_enabled = false
```

**NOTE:** changing this setting after the application has been initialized doesn't take any effect.

## Non-Rails usage

If you don't use Rails itself but have `ActiveSupport::Notifications` available in your application,
you can use the instrumentation feature with some additional configuration:

```ruby
# Enable `apply_rule` event by extending the base policy class
require "action_policy/rails/policy/instrumentation"
ActionPolicy::Base.include ActionPolicy::Policy::Rails::Instrumentation

# Enabled `authorize` event by extending the authorizer class
require "action_policy/rails/authorizer"
ActionPolicy::Authorizer.singleton_class.prepend ActionPolicy::Rails::Authorizer
```
