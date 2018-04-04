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
        return @__rules_cache__[rule] if @__rules_cache__.key?(rule)

        @__rules_cache__[rule] = super
      end
    end
  end
end
