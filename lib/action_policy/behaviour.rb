# frozen_string_literal: true

require "action_policy/behaviours/policy_for"
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
      record = implicit_authorization_target if record == :__undef__
      raise ArgumentError, "Record must be specified" if record.nil?

      policy = policy_for(record: record, **options)

      Authorizer.call(policy, authorization_rule_for(policy, to))
    end

    # Checks that an activity is allowed for the current context (e.g. user).
    #
    # Returns true of false.
    def allowed_to?(rule, record = :__undef__, **options)
      record = implicit_authorization_target if record == :__undef__
      raise ArgumentError, "Record must be specified" if record.nil?

      policy = policy_for(record: record, **options)

      policy.apply(authorization_rule_for(policy, rule))
    end

    # Apply scope to the target of the specified type.
    #
    # NOTE: policy lookup consists of the following steps:
    #   - first, check whether `with` option is present
    #   - secondly, try to infer policy class from `target` (non-raising lookup)
    #   - use `implicit_authorization_target` if none of the above works.
    def authorized(target, type: nil, as: :default, with: nil, **options)
      policy = with || policy_for(record: target, allow_nil: true, **options)
      policy ||= policy_for(record: implicit_authorization_target, **options)

      type ||= authorization_scope_type_for(policy, target)

      Authorizer.scopify(target, policy, type: type, name: as, **options)
    end

    def authorization_context
      return @__authorization_context if
        instance_variable_defined?(:@__authorization_context)

      @__authorization_context = self.class.authorization_targets
                                     .each_with_object({}) do |(key, meth), obj|
        obj[key] = send(meth)
      end
    end

    # Check that rule is defined for policy,
    # otherwise fallback to :manage? rule.
    def authorization_rule_for(policy, rule)
      policy.resolve_rule(rule)
    end

    # Infer scope type for target if none provided.
    # Raises an exception if type couldn't be inferred.
    def authorization_scope_type_for(policy, target)
      policy.resolve_scope_type(target)
    end

    # Override this method to provide implicit authorization target
    # that would be used in case `record` is not specified in
    # `authorize!` and `allowed_to?` call.
    #
    # It is also used to infer a policy for scoping (in `authorized` method).
    def implicit_authorization_target
      # no-op
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
