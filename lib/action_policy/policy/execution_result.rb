# frozen_string_literal: true

module ActionPolicy
  module Policy
    # Result of applying a policy rule
    #
    # This class could be extended by some modules to provide
    # additional functionality
    class ExecutionResult
      attr_reader :value, :policy, :rule

      def initialize(policy, rule)
        @policy = policy
        @rule = rule
      end

      # Populate the final value
      def load(value)
        @value = value
      end

      def success?
        @value == true
      end

      def fail?
        @value == false
      end

      def inspect
        "<#{policy}##{rule}: #{@value}>"
      end
    end
  end
end
