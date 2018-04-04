# frozen_string_literal: true

require "action_policy/behaviours/policy_for"
require "action_policy/behaviours/memoize"

module ActionPolicy
  # Provides `authorize!` and `allowed_to?` methods and
  # `authorize` class method to define authoriztion context.
  #
  # Could be included anywhere to perform authorization.
  module Behaviour
    include ActionPolicy::Behaviours::PolicyFor

    FALLBACK_RULE = :manage?

    def self.included(base)
      # Handle ActiveSupport::Concern differently
      if base.respond_to?(:class_methods)
        base.class_methods do
          include ClassMethods
        end
      else
        base.extend ClassMethods
      end
    end

    # Authorize action against a policy.
    #
    # Policy is inferred from record
    # (unless explicitly specified through `with` option).
    #
    # Raises `ActionPolicy::Unauthorized` if check failed.
    def authorize!(record, to:, **options)
      policy = policy_for(record: record, **options)

      Authorizer.call(policy, authorization_rule_for(policy, to))
    end

    # Checks that an activity is allowed for the current context (e.g. user).
    #
    # Returns true of false.
    def allowed_to?(rule, record, **options)
      policy = policy_for(record: record, **options)
      policy.apply(authorization_rule_for(policy, rule))
    end

    def authorization_context
      return @__authorization_context if
        instance_variable_defined?(:@__authorization_context)

      @__authorization_context = self.class.authorization_targets
                                     .each_with_object({}) do |(key, meth), obj|
        obj[key] = public_send(meth)
      end
    end

    # Check that rule is defined for policy,
    # otherwise fallback to :manage? rule.
    def authorization_rule_for(policy, rule)
      policy.respond_to?(rule) ? rule : FALLBACK_RULE
    end

    module ClassMethods # :nodoc:
      # Configure authorization context.
      #
      # For example:
      #
      #   class ApplicationController < ActionController::Base
      #     # Pass the value of `current_user` to authorization as `user`
      #     authorize :current_user, as: :user
      #   end
      #
      #   # Assuming that in your ApplicationPolicy
      #   class ApplicationPolicy < ActionPolicy::Base
      #     verify :user
      #   end
      def authorize(meth, as: nil)
        key = as || meth
        authorization_targets[key] = meth
      end

      def authorization_targets
        return @authorization_targets if instance_variable_defined?(:@authorization_targets)

        @authorization_targets =
          if superclass.respond_to?(:authorization_targets)
            superclass.authorization_targets.dup
          else
            {}
          end
      end
    end
  end
end
