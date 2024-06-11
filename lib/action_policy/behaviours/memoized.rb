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
        def policy_for(record:, **opts)
          __policy_memoize__(record, **opts) { super }
        end
      end

      def __policy_memoize__(record, **options)
        cache_key = policy_for_cache_key(record: record, **options)

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
