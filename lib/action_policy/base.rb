# frozen_string_literal: true

module ActionPolicy
  # Base class for application policies.
  class Base
    require "action_policy/policy/core"
    require "action_policy/policy/defaults"
    require "action_policy/policy/authorization"
    require "action_policy/policy/reasons"
    require "action_policy/policy/pre_check"
    require "action_policy/policy/aliases"
    require "action_policy/policy/scoping"
    require "action_policy/policy/cache"
    require "action_policy/policy/cached_apply"

    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Authorization
    include ActionPolicy::Policy::PreCheck
    include ActionPolicy::Policy::Reasons
    include ActionPolicy::Policy::Aliases
    include ActionPolicy::Policy::Scoping
    include ActionPolicy::Policy::Cache
    include ActionPolicy::Policy::CachedApply
    include ActionPolicy::Policy::Defaults
  end
end
