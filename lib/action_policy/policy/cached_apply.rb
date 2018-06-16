# frozen_string_literal: true

module ActionPolicy
  module Policy
    # Per-policy cache for applied rules.
    #
    # When you call `apply` twice on the same policy and for the same rule,
    # the check (and pre-checks) is only called once.
    module CachedApply
      def apply(rule)
        @__rules_cache__ ||= {}

        if @__rules_cache__.key?(rule)
          @result = @__rules_cache__[rule]
          return result.value
        end

        super

        @__rules_cache__[rule] = result

        result.value
      end
    end
  end
end
