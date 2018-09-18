# frozen_string_literal: true

module ActionPolicy
  module ScopeMatchers
    # Adds `params_filter` method as an alias
    # for `scope_for :ac_params`
    module ActionControllerParams
      def params_filter(*args, &block)
        scope_for :ac_params, *args, &block
      end
    end
  end
end

# Register params scope matcher
ActionPolicy::Base.scope_matcher :ac_params, ActionController::Parameters

# Add alias to base policy
ActionPolicy::Base.extend ActionPolicy::ScopeMatchers::ActionControllerParams
