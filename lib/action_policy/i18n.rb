# frozen_string_literal: true

module ActionPolicy
  module I18n # :nodoc:
    DEFAULT_UNAUTHORIZED_MESSAGE = "You are not authorized to perform this action"

    class << self
      def full_message(policy_class, rule, details = nil)
        candidates = candidates_for(policy_class, rule)

        options = {scope: :action_policy}
        options.merge!(details) unless details.nil?

        ::I18n.t(
          candidates.shift,
          default: candidates,
          **options
        )
      end

      private

      def candidates_for(policy_class, rule)
        policy_hierarchy = policy_class.ancestors.select { _1.respond_to?(:identifier) }
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
          rules.flat_map do |rule|
            if rule.is_a?(::Hash)
              rule.map do |key, details|
                ActionPolicy::I18n.full_message(policy_klass, key, details)
              end
            else
              ActionPolicy::I18n.full_message(policy_klass, rule)
            end
          end
        end
      end
    end)

    ActionPolicy::Policy::ExecutionResult.prepend(Module.new do
      def message
        ActionPolicy::I18n.full_message(policy, rule, details)
      end
    end)
  end
end
