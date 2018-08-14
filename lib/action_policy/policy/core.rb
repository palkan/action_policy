# frozen_string_literal: true

require "action_policy/behaviours/policy_for"
require "action_policy/policy/execution_result"
require "action_policy/utils/suggest_message"

unless "".respond_to?(:underscore)
  require "action_policy/ext/string_underscore"
  using ActionPolicy::Ext::StringUnderscore
end

module ActionPolicy
  # Raised when `resolve_rule` failed to find an approriate
  # policy rule method for the activity
  class UnknownRule < Error
    include ActionPolicy::SuggestMessage

    attr_reader :policy, :rule, :message

    def initialize(policy, rule)
      @policy = policy.class
      @rule = rule
      @message =
        "Couldn't find rule '#{@rule}' for #{@policy}" \
        "#{suggest(@rule, @policy.instance_methods - Object.instance_methods)}"
    end
  end

  module Policy
    # Core policy API
    module Core
      class << self
        def included(base)
          base.extend ClassMethods

          # Generate a new class for each _policy chain_
          # in order to extend it independently
          base.module_eval do
            @result_class = Class.new(ExecutionResult)

            # we need to make this class _named_,
            # 'cause anonymous classes couldn't be marshalled
            base.const_set(:APR, @result_class)
          end
        end
      end

      module ClassMethods # :nodoc:
        attr_writer :identifier

        def result_class
          return @result_class if instance_variable_defined?(:@result_class)
          @result_class = superclass.result_class
        end

        def identifier
          return @identifier if instance_variable_defined?(:@identifier)

          @identifier = name.sub(/Policy$/, "").underscore.to_sym
        end
      end

      include ActionPolicy::Behaviours::PolicyFor

      attr_reader :record, :result

      def initialize(record = nil)
        @record = record
      end

      # Returns a result of applying the specified rule (true of false).
      # Unlike simply calling a predicate rule (`policy.manage?`),
      # `apply` also calls pre-checks.
      def apply(rule)
        @result = self.class.result_class.new(self.class, rule)
        @result.load __apply__(rule)
      end

      # This method performs the rule call.
      # Override or extend it to provide custom functionality
      # (such as caching, pre checks, etc.)
      def __apply__(rule)
        public_send(rule)
      end

      # Wrap code that could modify result
      # to prevent the current result modification
      def with_clean_result
        was_result = @result
        res = yield
        @result = was_result
        res
      end

      # Returns a result of applying the specified rule to the specified record.
      # Under the hood a policy class for record is resolved
      # (unless it's explicitly set through `with` option).
      #
      # If record is `nil` then we uses the current policy.
      def allowed_to?(rule, record = :__undef__, **options)
        if record == :__undef__ && options.empty?
          __apply__(rule)
        else
          policy_for(record: record, **options).apply(rule)
        end
      end

      # An alias for readability purposes
      def check?(*args)
        allowed_to?(*args)
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
