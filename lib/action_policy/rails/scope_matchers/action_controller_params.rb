# frozen_string_literal: true

module ActionPolicy
  module ScopeMatchers
    # Adds `params_filter` method as an alias
    # for `scope_for :action_controller_params`
    module ActionControllerParams
      def params_filter(*args, &block)
        scope_for :action_controller_params, *args, &block
      end
    end
  end
end

# Register params scope matcher
ActionPolicy::Base.scope_matcher :action_controller_params, ActionController::Parameters

# Add alias to base policy
ActionPolicy::Base.extend ActionPolicy::ScopeMatchers::ActionControllerParams
