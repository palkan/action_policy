# frozen_string_literal: true

module ActionPolicy # :nodoc:
  module Policy
    module Rails
      # Add ActiveSupport::Notifications support.
      #
      # Fires `action_policy.apply_rule` event on every `#apply` call.
      # Fires `action_policy.init` event on every policy initialization.
      module Instrumentation
        INIT_EVENT_NAME = "action_policy.init"
        APPLY_EVENT_NAME = "action_policy.apply_rule"

        def initialize(record = nil, **params)
          event = {policy: self.class.name}
          ActiveSupport::Notifications.instrument(INIT_EVENT_NAME, event) { super }
        end

        def apply(rule)
          event = {policy: self.class.name, rule: rule.to_s}
          ActiveSupport::Notifications.instrument(APPLY_EVENT_NAME, event) do
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
