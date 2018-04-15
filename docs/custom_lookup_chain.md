# Custom Lookup Chain

Action Policy's lookup chain is just an array of _probes_ (lambdas with a specific interface).

The lookup process itself is pretty simple:
- Call the first probe;
- Return the result if it is not `nil`;
- Go to the next probe.

You can override the default chain with your own. For example:

```ruby
ActionPolicy::LookupChain.chain = [
  # Probe accepts record as the first argument
  # and arbitrary options (passed to `authorize!` / `allowed_to?` call)
  lambda do |record, **options|
    # your custom lookup logic
  end
]
```

## NullPolicy example

Let's consider a simple example of extending the existing lookup chain with one more probe.

Suppose that we want to have a fallback policy (policy used when none found for the resource) instead of raising an `ActionPolicy::NotFound` error.

Let's call this policy a `NullPolicy`:

```ruby
class NullPolicy < ActionPolicy::Base
  default_rule :any?

  def any?
    false
  end
end
```

Here we use the [default rule](aliases.md#default-rule) to handle any rule applied.

Now we need to add a simple probe to the end of our lookup chain:

```ruby
ActionPolicy::LookupChain.chain << ->(_, _) { NullPolicy }
```

That's it!
