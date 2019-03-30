# frozen_string_literal: true

module ActionPolicy # :nodoc:
  module Rails
    # Add instrumentation for `authorize!` method
    module Authorizer
      EVENT_NAME = "action_policy.authorize"

      def authorize(policy, rule)
        event = {policy: policy.class.name, rule: rule.to_s}
        ActiveSupport::Notifications.instrument(EVENT_NAME, event) do
          res = super
          event[:cached] = policy.result.cached?
          event[:value] = policy.result.value
          res
        end
      end
    end
  end
end
