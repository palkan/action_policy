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
      require "action_policy/ext/policy_cache_key"
      using ActionPolicy::Ext::PolicyCacheKey

      class << self
        def prepended(base)
          base.prepend InstanceMethods
        end

        alias included prepended
      end

      module InstanceMethods # :nodoc:
        def policy_for(record:, **opts)
          __policy_memoize__(record, opts) { super(record: record, **opts) }
        end
      end

      def __policy_memoize__(record, with: nil, namespace: nil, **_opts)
        record_key = record._policy_cache_key(use_object_id: true)
        cache_key = "#{namespace}/#{with}/#{record_key}"

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
