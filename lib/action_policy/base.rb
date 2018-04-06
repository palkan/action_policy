# frozen_string_literal: true

module ActionPolicy
  # Base class for application policies.
  class Base
    require "action_policy/policy/core"
    require "action_policy/policy/defaults"
    require "action_policy/policy/verification"
    require "action_policy/policy/reasons"
    require "action_policy/policy/cached_apply"
    require "action_policy/policy/aliases"

    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Defaults
    prepend ActionPolicy::Policy::Verification
    prepend ActionPolicy::Policy::Reasons
    prepend ActionPolicy::Policy::CachedApply
    prepend ActionPolicy::Policy::Aliases
  end
end
