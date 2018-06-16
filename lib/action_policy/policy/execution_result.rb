# frozen_string_literal: true

module ActionPolicy
  module Policy
    # Result of applying a policy rule
    #
    # This class could be extended by some modules to provide
    # additional functionality
    class ExecutionResult
      attr_reader :value

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
    end
  end
end
