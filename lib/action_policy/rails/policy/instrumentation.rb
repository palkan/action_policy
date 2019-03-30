# frozen_string_literal: true

module ActionPolicy # :nodoc:
  module Policy
    module Rails
      # Add ActiveSupport::Notifications support.
      #
      # Fires `action_policy.apply_rule` event on every `#apply` call.
      module Instrumentation
        EVENT_NAME = "action_policy.apply_rule"

        def apply(rule)
          event = {policy: self.class.name, rule: rule.to_s}
          ActiveSupport::Notifications.instrument(EVENT_NAME, event) do
            res = super
            event[:cached] = result.cached?
            event[:value] = result.value
            res
          end
        end
      end
    end
  end
end
