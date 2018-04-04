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
    #   include ActionPolicy::Memoize
    #
    #   record = User.first
    #   policy = policy_for(record)
    #   policy2 = policy_for(record)
    #
    #   policy.equal?(policy) #=> true
    #
    #   policy.equal?(policy_for(record, with: CustomPolicy)) #=> false
    module Memoized
      def policy_for(record:, with: nil)
        policy_class = with || ::ActionPolicy.lookup(record)
        __policy_memoize__(policy_class, record) { super(record: record, with: policy_class) }
      end

      def __policy_memoize__(klass, record)
        record_key = record.respond_to?(:cache_key) ? record.cache_key : record.object_id
        cache_key = "#{klass}/#{record_key}"

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
