# frozen_string_literal: true

require "action_policy/version"

module ActionPolicy # :nodoc:
  # By default cache namespace (or prefix) contains major and minor version of the gem
  CACHE_NAMESPACE = "acp:#{ActionPolicy::VERSION.split('.').take(2).join('.')}"

  require "action_policy/ext/policy_cache_key"
  using ActionPolicy::Ext::PolicyCacheKey

  module Policy
    # Provides long-lived cache through ActionPolicy.cache_store.
    #
    # NOTE: if cache_store is nil then we silently skip all the caching.
    module Cache
      class << self
        def prepended(base)
          base.extend ClassMethods
          base.prepend InstanceMethods
        end

        alias included prepended
      end

      def cache_namespace
        ActionPolicy::CACHE_NAMESPACE
      end

      def cache_key(rule)
        "#{cache_namespace}/#{context_cache_key}/" \
        "#{record._policy_cache_key}/#{self.class.name}/#{rule}"
      end

      def context_cache_key
        authorization_context.map { |_k, v| v._policy_cache_key.to_s }.join("/")
      end

      def apply_with_cache(rule)
        options = self.class.cached_rules.fetch(rule)

        ActionPolicy.cache_store.fetch(cache_key(rule), options) { yield }
      end

      module InstanceMethods # :nodoc:
        def apply(rule)
          return super if ActionPolicy.cache_store.nil? ||
                          !self.class.cached_rules.key?(rule)

          apply_with_cache(rule) { super }
        end
      end

      module ClassMethods # :nodoc:
        def cache(*rules, **options)
          rules.each do |rule|
            cached_rules[rule] = options
          end
        end

        def cached_rules
          return @cached_rules if instance_variable_defined?(:@cached_rules)

          @cached_rules =
            if superclass.respond_to?(:cached_rules)
              superclass.cached_rules.dup
            else
              {}
            end
        end
      end
    end
  end
end
