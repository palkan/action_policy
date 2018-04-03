# frozen_string_literal: true

module ActionPolicy
  # Base class for application policies.
  class Base
    require "action_policy/core"
    require "action_policy/defaults"
    require "action_policy/policy_for"
    require "action_policy/verification"
    require "action_policy/reasons"

    include Core
    include Defaults
    include PolicyFor
    include Verification
    prepend Reasons
  end
end
