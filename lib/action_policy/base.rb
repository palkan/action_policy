# frozen_string_literal: true

module ActionPolicy
  # Base class for application policies.
  class Base
    require "action_policy/policy/core"
    require "action_policy/policy/defaults"
    require "action_policy/policy/verification"
    require "action_policy/policy/reasons"
    require "action_policy/policy/cached_apply"

    require "action_policy/behaviours/policy_for"

    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Defaults
    include ActionPolicy::Behaviours::PolicyFor
    prepend ActionPolicy::Policy::Verification
    prepend ActionPolicy::Policy::Reasons
    prepend ActionPolicy::Policy::CachedApply
  end
end
