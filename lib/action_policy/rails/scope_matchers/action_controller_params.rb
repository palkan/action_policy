# frozen_string_literal: true

module ActionPolicy
  module ScopeMatchers
    # Adds `params_filter` method as an alias
    # for `scope_for :action_controller_params`
    module ActionControllerParams
      def params_filter(...)
        scope_for(:action_controller_params, ...)
      end
    end
  end
end

# Add alias to base policy
ActionPolicy::Base.extend ActionPolicy::ScopeMatchers::ActionControllerParams

ActiveSupport.on_load(:action_controller) do
  # Register params scope matcher
  ActionPolicy::Base.scope_matcher :action_controller_params, ActionController::Parameters
end
