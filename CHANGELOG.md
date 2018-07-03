## master

- [Fix [#16](https://github.com/palkan/action_policy/issues/16)] Add ability to disable namespace resolution cache. ([@palkan][])

  We cache namespaced policy resolution for better performance (it could affect performance when we look up a policy from a deeply nested module context).

  It could be disabled by setting `ActionPolicy::LookupChain.namespace_cache_enabled = false`. It's enabled by default unless `RACK_ENV` env var is specified and is not equal to `"production"` (e.g. when `RACK_ENV=test` the cache is disabled).

  When using Rails it's enabled only in production mode but could be configured through setting the `config.config.action_policy.namespace_cache_enabled` parameter.

- [Fix [#18](https://github.com/palkan/action_policy/issues/18)] Clarify documentation around, and fix the way `resolve_rule` resolves rules and rule aliases when subclasses are involved. ([@brendon][])

## 0.2.2 (2018-07-01)

- [Fix [#29](https://github.com/palkan/action_policy/issues/29)] Fix loading cache middleware. ([@palkan][])


- Use `send` instead of `public_send` to get the `authorization_context` so that contexts such as
  `current_user` can be `private` in the controller. ([@brendon][])

- Fix railtie initialisation for Rails < 5. ([@brendon][])

## 0.2.1 (yanked)

## 0.2.0 (2018-06-17)

- Make `action_policy` JRuby-compatible. ([@palkan][])

- Add `reasons.details`. ([@palkan][])

  ```ruby
  rescue_from ActionPolicy::Unauthorized do |ex|
    ex.result.reasons.details #=> { stage: [:show?] }
  end
  ```

- Add `ExecutionResult`. ([@palkan][])

  ExecutionResult contains all the rule application artifacts: the result (`true` / `false`),
  failures reasons.

  This value is now stored in a cache (if any) instead of just the call result (`true` / `false`).

- Add `Policy.identifier`. ([@palkan][])

## 0.1.4 (2018-06-06)

- Fix Railtie injection hook. ([@palkan][])

- Fix Ruby 2.3 compatibility. ([@palkan])

## 0.1.3 (2018-05-20)

- Fix modules order in `ActionPolicy::Base`. ([@ilyasgaraev][])

## 0.1.2 (2018-05-09)

- [Fix [#6](https://github.com/palkan/action_policy/issues/6)] Fix controller concern to work with API/Metal controllers. ([@palkan][])

## 0.1.1 (2018-04-21)

- [Fix [#2](https://github.com/palkan/action_policy/issues/2)] Fix namespace lookup when Rails autoloading is involved. ([@palkan][])

## 0.1.0 (2018-04-17)

- Initial pre-release version. ([@palkan][])

[@palkan]: https://github.com/palkan
[@ilyasgaraev]: https://github.com/ilyasgaraev
[@brendon]: https://github.com/brendon
