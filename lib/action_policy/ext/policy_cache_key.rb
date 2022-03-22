# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Adds #_policy_cache_key method to Object,
    # which just call #policy_cache_key or #cache_key
    # or #object_id (if `use_object_id` parameter is set to true).
    #
    # For other core classes returns string representation.
    #
    # Raises ArgumentError otherwise.
    module PolicyCacheKey # :nodoc: all
      module ObjectExt
        def _policy_cache_key(use_object_id: false)
          return policy_cache_key if respond_to?(:policy_cache_key)
          return cache_key_with_version if respond_to?(:cache_key_with_version)
          return cache_key if respond_to?(:cache_key)

          return object_id.to_s if use_object_id == true

          raise ArgumentError, "object is not cacheable"
        end
      end

      refine Object do
        import_methods ObjectExt
      end

      refine NilClass do
        def _policy_cache_key(*) = ""
      end

      refine TrueClass do
        def _policy_cache_key(*) = "t"
      end

      refine FalseClass do
        def _policy_cache_key(*) = "f"
      end

      refine String do
        def _policy_cache_key(*) = self
      end

      refine Symbol do
        def _policy_cache_key(*) = to_s
      end

      if RUBY_PLATFORM.match?(/java/i)
        refine Integer do
          def _policy_cache_key(*) = to_s
        end

        refine Float do
          def _policy_cache_key(*) = to_s
        end
      else
        refine Numeric do
          def _policy_cache_key(*) = to_s
        end
      end

      refine Time do
        def _policy_cache_key(*) = to_s
      end

      refine Module do
        def _policy_cache_key(*) = name
      end
    end
  end
end
