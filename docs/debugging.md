# Debug Helpers

**NOTE:** this functionality requires two additional gems to be available in the app:

- [unparser](https://github.com/mbj/unparser)
- [method_source](https://github.com/banister/method_source).

We usually describe policy rules using _boolean expressions_ (e.g. `A or (B and C)` where each of `A`, `B` and `C` is a simple boolean expression or predicate method).

When dealing with complex policies, it could be hard to figure out which predicate/check made policy to fail.

The `Policy#pp(rule)` method aims to help debug such situations.

Consider a (synthetic) example:

```ruby
def feed?
  (admin? || allowed_to?(:access_feed?)) &&
    (user.name == "Jack" || user.name == "Kate")
end

```

Suppose that you want to debug this rule ("Why does it return false?").
You can drop a [`binding.pry`](https://github.com/deivid-rodriguez/pry-byebug) (or `binding.irb`) right at the beginning of the method:

```ruby
def feed?
  binding.pry # rubocop:disable Lint/Debugger
  #...
end
```

Now, run your code and trigger the breakpoint (i.e., run the method):

```
# now you can preview the execution of the rule using the `pp` method (defined on the policy instance)
pry> pp :feed?
MyPolicy#feed?
↳ (
    admin? #=> false
    OR
    allowed_to?(:access_feed?) #=> true
  )
  AND
  (
    user.name == "Jack" #=> false
    OR
    user.name == "Kate" #=> true
  )

# you can also check other rules or methods as well
pry> pp :admin?
MyPolicy#admin?
↳ user.admin? #=> false
```

## Compatibility with debugging tools

Since we partially evaluate code within a policy rule, pretty printing could get stuck if you have debugging breakpoints.
By default, we ignore `binding.pry` and `binding.irb` expressions (you will see a `<skipped>` comment in the output). If you're using an alternative debugging technique, you can add a regexp to ignore the corresponding expression:

```ruby
ActionPolicy::PrettyPrint.ignore_expressions << /\bdebug\b/
```
