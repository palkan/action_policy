# frozen_string_literal: true

module ActionPolicy
  # Base class for application policies.
  class Base
    require "action_policy/policy/core"
    require "action_policy/policy/defaults"
    require "action_policy/policy/verification"
    require "action_policy/policy/reasons"
    require "action_policy/policy/pre_check"
    require "action_policy/policy/aliases"
    require "action_policy/policy/cached_apply"

    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Defaults
    include ActionPolicy::Policy::Verification
    include ActionPolicy::Policy::Reasons
    include ActionPolicy::Policy::PreCheck
    include ActionPolicy::Policy::Aliases
    include ActionPolicy::Policy::CachedApply
  end
end
