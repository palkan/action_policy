# frozen_string_literal: true

module ActionPolicy
  module PerThreadCache # :nodoc:
    CACHE_KEY = "action_policy.per_thread_cache"

    class << self
      attr_writer :enabled

      def enabled?
        @enabled == true
      end

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
          __policy_thread_memoize__(record, opts) { super(record: record, **opts) }
        end
      end

      def __policy_thread_memoize__(record, with: nil, namespace: nil, **_opts)
        record_key = record._policy_cache_key(use_object_id: true)
        cache_key = "#{namespace}/#{with}/#{record_key}"

        ActionPolicy::PerThreadCache.fetch(cache_key) { yield }
      end
    end
  end
end
