# Policy Lookup

Action Policy tries to automatically infer policy class from the target using the following _probes_:

1. If the target is a `Symbol`:

    a) Try `"#{target.to_s.camelize}Policy"` as a `policy_name` (see below);

    b) If `String#classify` is available, e.g. when using Rails' ActiveSupport, try `"#{target.to_s.classify}Policy"`;

2. If the target responds to `policy_class`, then use it;
3. If the target's class responds to `policy_class`, then use it;
4. If the target or the target's class responds to `policy_name`, then use it (the `policy_name` should end with `Policy` as it's not appended automatically);
5. Otherwise, use `#{target.class.name}Policy`.

> \* [Namespaces](namespaces.md) could be also be considered when `namespace` option is set.

You can call `ActionPolicy.lookup(record, options)` to infer policy class for the record.

When no policy class is found, an `ActionPolicy::NotFound` error is raised.

You can [customize lookup](custom_lookup_chain.md) logic if necessary.
