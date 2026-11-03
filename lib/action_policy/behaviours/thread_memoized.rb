# frozen_string_literal: true

module ActionPolicy
  module PerThreadCache # :nodoc:
    CACHE_KEY = "action_policy.per_thread_cache"

    class << self
      attr_writer :enabled

      def enabled?() = @enabled == true

      def fetch(key)
        return yield unless enabled?

        store = (Thread.current[CACHE_KEY] ||= {})

        return store[key] if store.key?(key)

        store[key] = yield
      end

      def clear_all
        Thread.current[CACHE_KEY] = {}
      end
    end

    # Turn off by default in test env
    self.enabled = !(ENV["RAILS_ENV"] == "test" || ENV["RACK_ENV"] == "test")
  end

  module Behaviours
    # Per-thread memoization for policies.
    #
    # Used by `policy_for` to re-use policy object for records.
    #
    # NOTE: don't forget to clear thread cache with ActionPolicy::PerThreadCache.clear_all
    module ThreadMemoized
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

          __policy_thread_memoize__(cache_key) { super(record:, **opts, resolved_context:, cache_key:) }
        end
      end

      def __policy_thread_memoize__(cache_key)
        ActionPolicy::PerThreadCache.fetch(cache_key) { yield }
      end
    end
  end
end
