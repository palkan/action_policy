# frozen_string_literal: true

module ActionPolicy
  module Behaviours
    # Per-instance memoization for policies.
    #
    # Used by `policy_for` to re-use policy object for records.
    #
    # Example:
    #
    #   include ActionPolicy::Behaviour
    #   include ActionPolicy::Memoized
    #
    #   record = User.first
    #   policy = policy_for(record)
    #   policy2 = policy_for(record)
    #
    #   policy.equal?(policy) #=> true
    #
    #   policy.equal?(policy_for(record, with: CustomPolicy)) #=> false
    module Memoized
      class << self
        def prepended(base)
          base.prepend InstanceMethods
        end

        alias_method :included, :prepended
      end

      module InstanceMethods # :nodoc:
        def policy_for(record:, context: nil, resolved_context: nil, cache_key: nil, **opts)
          resolved_context ||= policy_for_context(context)
          cache_key ||= policy_for_cache_key(record:, context: resolved_context, **opts)
          __policy_memoize__(cache_key) { super(record:, **opts, resolved_context:, cache_key:) }
        end
      end

      def __policy_memoize__(cache_key)
        return __policies_cache__[cache_key] if
          __policies_cache__.key?(cache_key)

        policy = yield

        __policies_cache__[cache_key] = policy
      end

      def __policies_cache__
        @__policies_cache__ ||= {}
      end
    end
  end
end
