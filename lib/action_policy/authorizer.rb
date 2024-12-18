# frozen_string_literal: true

module ActionPolicy
  # Raised when `authorize!` check fails
  class Unauthorized < Error
    attr_reader :policy, :rule, :result

    # NEXT_RELEASE: remove result fallback
    def initialize(policy, rule, result = policy.result)
      @policy = policy.class
      @rule = rule
      @result = result

      super("Not authorized: #{@policy}##{@rule} returns false")
    end
  end

  # The main purpose of this module is to extact authorize actions
  # from everything else to make it easily testable.
  module Authorizer
    class << self
      # Performs authorization, raises an exception when check failed.
      def call(policy, rule)
        res = authorize(policy, rule)
        return if res.success?

        raise(::ActionPolicy::Unauthorized.new(policy, rule, res))
      end

      def authorize(policy, rule)
        policy.apply_r(rule)
      end

      # Applies scope to the target
      def scopify(target, policy, **options)
        policy.apply_scope(target, **options)
      end
    end
  end
end
