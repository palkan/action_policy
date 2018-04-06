# frozen_string_literal: true

require "action_policy/behaviours/policy_for"

module ActionPolicy
  # Raised when `resolve_rule` failed to find an approriate
  # policy rule method for the activity
  class UnknownRule < Error
    attr_reader :policy, :rule, :message

    def initialize(policy, rule)
      @policy = policy.class
      @rule = rule
      @message = "Couldn't find rule '#{@rule}' for #{@policy}"
    end
  end

  module Policy
    # Core policy API
    module Core
      include ActionPolicy::Behaviours::PolicyFor

      attr_reader :record

      def initialize(record = nil)
        @record = record
      end

      # Returns a result of applying the specified rule.
      # Unlike simply calling a predicate rule (`policy.manage?`),
      # `apply` also calls pre-checks.
      def apply(rule)
        public_send(rule)
      end

      # Returns a result of applying the specified rule to the specified record.
      # Under the hood a policy class for record is resolved
      # (unless it's explicitly set through `with` option).
      #
      # If record is `nil` then we uses the current policy.
      def allowed_to?(rule, record = :__undef__, **options)
        policy =
          if record == :__undef__
            self
          else
            policy_for(record: record, **options)
          end

        policy.apply(rule)
      end

      # Returns a rule name (policy method name) for activity.
      #
      # By default, rule name is equal to activity name.
      #
      # Raises ActionPolicy::UknownRule when rule is not found in policy.
      def resolve_rule(activity)
        raise UnknownRule.new(self, activity) unless
          respond_to?(activity)
        activity
      end
    end
  end
end
