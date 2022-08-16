# frozen_string_literal: true

require "action_policy/behaviours/policy_for"
require "action_policy/behaviours/scoping"
require "action_policy/behaviours/memoized"
require "action_policy/behaviours/thread_memoized"
require "action_policy/behaviours/namespaced"

require "action_policy/authorizer"

module ActionPolicy
  # Provides `authorize!` and `allowed_to?` methods and
  # `authorize` class method to define authorization context.
  #
  # Could be included anywhere to perform authorization.
  module Behaviour
    include ActionPolicy::Behaviours::PolicyFor
    include ActionPolicy::Behaviours::Scoping

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
    def authorize!(record = :__undef__, to:, **options)
      policy = lookup_authorization_policy(record, **options)

      Authorizer.call(policy, authorization_rule_for(policy, to))
    end

    # Checks that an activity is allowed for the current context (e.g. user).
    #
    # Returns true of false.
    def allowed_to?(rule, record = :__undef__, **options)
      policy = lookup_authorization_policy(record, **options)

      policy.apply(authorization_rule_for(policy, rule))
    end

    # Returns the authorization result object after applying a specified rule to a record.
    def allowance_to(rule, record = :__undef__, **options)
      policy = lookup_authorization_policy(record, **options)

      policy.apply(authorization_rule_for(policy, rule))
      policy.result
    end

    def authorization_context
      @_authorization_context ||= build_authorization_context
    end

    private def build_authorization_context
      self.class.authorization_targets
        .each_with_object({}) do |(key, meth), obj|
        obj[key] = send(meth)
      end
    end

    # Check that rule is defined for policy,
    # otherwise fallback to :manage? rule.
    def authorization_rule_for(policy, rule)
      policy.resolve_rule(rule)
    end

    def lookup_authorization_policy(record, with: nil, **options) # :nodoc:
      if :__undef__ == record # rubocop:disable Style/YodaCondition
        record =
          if with
            implicit_authorization_target
          else
            implicit_authorization_target!
          end
      end

      Kernel.raise ArgumentError, "Record or policy must be specified" if record.nil? && with.nil?

      policy_for(record: record, with: with, **options)
    end

    module ClassMethods # :nodoc:
      # Configure authorization context.
      #
      # For example:
      #
      #   class ApplicationController < ActionController::Base
      #     # Pass the value of `current_user` to authorization as `user`
      #     authorize :user, through: :current_user
      #   end
      #
      #   # Assuming that in your ApplicationPolicy
      #   class ApplicationPolicy < ActionPolicy::Base
      #     authorize :user
      #   end
      def authorize(key, through: nil)
        meth = through || key
        authorization_targets[key] = meth
      end

      def authorization_targets
        return @authorization_targets if instance_variable_defined?(:@authorization_targets)

        @authorization_targets = if superclass.respond_to?(:authorization_targets)
          superclass.authorization_targets.dup
        else
          {}
        end
      end
    end
  end
end
