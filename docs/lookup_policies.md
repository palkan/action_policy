# Lookup Policies

Action Policy tries to automatically infer policy class from the target using the following _probes_:

1) If target responds to `policy_class`, then use it

2) If target's class responds to `policy_class`, then use it

3\*) If target's class responds to `policy_name` then use `#{target.class.policy_name}Policy`

4) Otherwise use `#{target.class.name}Policy`.

> \* [Namespaces](namespaces.md) could be also considered when `namespace` options is set.

You can call `ActionPolicy.lookup(record, options)` to infer policy class for the record.

When no policy class is found `ActionPolicy::NotFound` error is raised.
