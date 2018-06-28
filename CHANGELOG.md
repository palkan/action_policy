## master

- Use `send` instead of `public_send` to get the `authorization_context` so that contexts such as
  `current_user` can be `private` in the controller. ([@brendon][])

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
