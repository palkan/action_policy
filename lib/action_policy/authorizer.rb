# frozen_string_literal: true

module ActionPolicy
  # Raised when `authorize!` check fails
  class Unauthorized < Error
    attr_reader :policy, :rule, :reasons

    def initialize(policy, rule)
      @policy = policy.class
      @rule = rule
      @reasons = policy.reasons
    end
  end

  # Performs authorization, raises an exception when check failed.
  #
  # The main purpose of this module is to extact authorize action
  # from everything else to make it easily testable.
  module Authorizer
    class << self
      def call(policy, rule)
        policy.apply(rule) ||
          raise(::ActionPolicy::Unauthorized.new(policy, rule))
      end
    end
  end
end
