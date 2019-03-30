# frozen_string_literal: true

module ActionPolicy
  # Raised when `authorize!` check fails
  class Unauthorized < Error
    attr_reader :policy, :rule, :result

    def initialize(policy, rule)
      @policy = policy.class
      @rule = rule
      @result = policy.result

      super("Not Authorized")
    end
  end

  # The main purpose of this module is to extact authorize actions
  # from everything else to make it easily testable.
  module Authorizer
    class << self
      # Performs authorization, raises an exception when check failed.
      def call(policy, rule)
        authorize(policy, rule) ||
          raise(::ActionPolicy::Unauthorized.new(policy, rule))
      end

      def authorize(policy, rule)
        policy.apply(rule)
      end

      # Applies scope to the target
      def scopify(target, policy, **options)
        policy.apply_scope(target, **options)
      end
    end
  end
end
