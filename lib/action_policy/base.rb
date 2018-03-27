# frozen_string_literal: true

module ActionPolicy
  # Superclass for user-defined policies.
  # Contains rules for standard CRUD operations:
  # - `index?` (=`true`)
  # - `create?` (=`false`)
  # - `new?` as an alias for `create?`
  # - `manage?` as a fallback for all unspecified rules.
  class Base
    require "action_policy/defaults"
    require "action_policy/verification"
    require "action_policy/reasons"

    include Defaults
    include Verification
    prepend Reasons

    # Returns a result of applying the specified rule.
    # Unlike simply calling a predicate rule (`policy.manage?`),
    # `apply` also calls pre-checks.
    def apply(rule)
      public_send(rule)
    end
  end
end
