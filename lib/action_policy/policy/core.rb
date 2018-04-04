# frozen_string_literal: true

module ActionPolicy
  module Policy
    # Core policy API
    module Core
      attr_reader :record

      def initialize(record)
        @record = record
      end

      # Returns a result of applying the specified rule.
      # Unlike simply calling a predicate rule (`policy.manage?`),
      # `apply` also calls pre-checks.
      def apply(rule)
        public_send(rule)
      end
    end
  end
end
