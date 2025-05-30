# frozen_string_literal: true

require "action_policy/behaviours/policy_for"
require "action_policy/policy/execution_result"
require "action_policy/utils/suggest_message"
require "action_policy/utils/pretty_print"

unless "".respond_to?(:underscore)
  require "action_policy/ext/string_underscore"
  using ActionPolicy::Ext::StringUnderscore
end

module ActionPolicy
  using RubyNext

  # Raised when `resolve_rule` failed to find an approriate
  # policy rule method for the activity
  class UnknownRule < Error
    include ActionPolicy::SuggestMessage

    attr_reader :policy, :rule, :message

    def initialize(policy, rule)
      @policy = policy.class
      @rule = rule
      @message = "Couldn't find rule '#{@rule}' for #{@policy}" \
        "#{suggest(@rule, @policy.instance_methods - Object.instance_methods)}"
    end
  end

  class NonPredicateRule < UnknownRule
    def initialize(policy, rule)
      @policy = policy.class
      @rule = rule
      @message = "The rule '#{@rule}' of '#{@policy}' must ends with ? (question mark)\nDid you mean? #{@rule}?"
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

      attr_reader :record

      # NEXT_RELEASE: deprecate `record` arg, migrate to `record: nil`
      def initialize(record = nil, *)
        @record = record
      end

      # Returns a result of applying the specified rule (true of false).
      # Unlike simply calling a predicate rule (`policy.manage?`),
      # `apply` also calls pre-checks.
      def apply(rule)
        res = apply_r(rule)

        # DEPRECATED (we still rely on it in tests)
        @result = res

        res.value
      end

      # NEXT_RELEASE: This is gonna be #apply in 1.0
      def apply_r(rule) # :nodoc:
        with_result(rule) do |result|
          catch :policy_fulfilled do
            result.load __apply__(resolve_rule(rule))
          end

          result
        end
      end

      def deny!
        result&.load false
        throw :policy_fulfilled
      end

      def allow!
        result&.load true
        throw :policy_fulfilled
      end

      # This method performs the rule call.
      # Override or extend it to provide custom functionality
      # (such as caching, pre checks, etc.)
      def __apply__(rule) = public_send(rule)

      # Prepare a new result object for the next rule application.
      # It's stored in the thread-local storage to be accessible from within the policy.
      def with_result(rule) # :nodoc:
        result = self.class.result_class.new(self.class, rule)

        Thread.current[:__action_policy_result__] ||= []
        Thread.current[:__action_policy_result__] << result

        yield result
      ensure
        Thread.current[:__action_policy_result__]&.pop
      end

      # Returns a result of applying the specified rule to the specified record.
      # Under the hood a policy class for record is resolved
      # (unless it's explicitly set through `with` option).
      #
      # If record is `nil` then we uses the current policy.
      def allowed_to?(rule, record = :__undef__, **options)
        if (record == :__undef__ || record == self.record) && options.empty?
          __apply__(resolve_rule(rule))
        else
          policy_for(record: record, **options).then do |policy|
            policy.apply(policy.resolve_rule(rule))
          end
        end
      end

      # An alias for readability purposes
      def check?(*args, **hargs) = allowed_to?(*args, **hargs)

      # Returns a rule name (policy method name) for activity.
      #
      # By default, rule name is equal to activity name.
      #
      # Raises ActionPolicy::UnknownRule when rule is not found in policy.
      def resolve_rule(activity)
        raise UnknownRule.new(self, activity) unless
          respond_to?(activity)
        activity
      end

      # Returns the result object for the last rule application within the given
      # execution context (Thread or Fiber)
      def result
        # FIXME: Remove ivar fallback after 1.0
        Thread.current[:__action_policy_result__]&.last || @result
      end

      # Return annotated source code for the rule
      # NOTE: require "method_source" and "prism" gems to be installed.
      # Otherwise returns empty string.
      def inspect_rule(rule) = PrettyPrint.print_method(self, rule)

      # Helper for printing the annotated rule source.
      # Useful for debugging: type `pp :show?` within the context of the policy
      # to preview the rule.
      def pp(rule)
        with_result(rule) do
          header = "#{self.class.name}##{rule}"
          source = inspect_rule(rule)
          $stdout.puts "#{header}\n#{source}"
        end
      end
    end
  end
end
