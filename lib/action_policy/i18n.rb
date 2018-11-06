# frozen_string_literal: true

module ActionPolicy
  module I18n # :nodoc:
    DEFAULT_UNAUTHORIZED_MESSAGE = "You are not authorized to perform this action"

    class << self
      def full_message(policy_class, rule)
        candidates = candidates_for(policy_class, rule)

        ::I18n.t(
          candidates.shift,
          default: candidates,
          scope: :action_policy
        )
      end

      private

      def candidates_for(policy_class, rule)
        policy_hierarchy = policy_class.ancestors.select { |klass| klass.respond_to?(:identifier) }
        [
          *policy_hierarchy.map { |klass| :"policy.#{klass.identifier}.#{rule}" },
          :"policy.#{rule}",
          :unauthorized,
          DEFAULT_UNAUTHORIZED_MESSAGE
        ]
      end
    end

    ActionPolicy::Policy::FailureReasons.prepend(Module.new do
      def full_messages
        reasons.flat_map do |policy_klass, rules|
          rules.map { |rule| ActionPolicy::I18n.full_message(policy_klass, rule) }
        end
      end
    end)

    ActionPolicy::Policy::ExecutionResult.prepend(Module.new do
      def message
        ActionPolicy::I18n.full_message(policy, rule)
      end
    end)
  end
end
