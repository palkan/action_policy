# frozen_string_literal: true

require "active_support/concern"
require "action_policy/policy_for"

module ActionPolicy
  # Controller concern.
  # Add `authorize!` and `allowed_to?` methods,
  # provide `verify_authorized` hook.
  module Controller
    extend ActiveSupport::Concern

    include PolicyFor

    included do
      private :authorization_context
    end

    # Authorize action against a policy.
    #
    # Policy is inferred from record
    # (unless explicitly specified through `with` option).
    #
    # If action is not provided, it's inferred from `action_name`.
    #
    # If record is not provided, tries to infer the resource class
    # from controller name (i.e. `controller_name.classify.safe_constantize`).
    #
    # Raises `ActionPolicy::Unauthorized` if check failed.
    def authorize!(record = :__undef__, to: nil, **options)
      record = controller_name.classify.safe_constantize if
        record == :__undef__

      policy = policy_for(record: record, **options)

      rule = to || "#{action_name}?"

      policy.apply(rule) || raise(::ActionPolicy::Unauthorized.new(policy, rule))
    end

    # Checks that an activity is allowed for the current context (e.g. user).
    #
    # If record is not provided, tries to infer the resource class
    # from controller name (i.e. `controller_name.classify.safe_constantize`).
    #
    # Returns true of false.
    def allowed_to?(rule, record = :__undef__, **options)
      record ||= controller_name.classify.safe_constantize if
        record == :__undef__

      policy = policy_for(record: record, **options)

      policy.apply(rule)
    end

    def authorization_context
      return @__authorization_context if
        instance_variable_defined?(:@__authorization_context)

      @__authorization_context = self.class.authorization_targets
                                     .each_with_object({}) do |(key, meth), obj|
        obj[key] = public_send(meth)
      end
    end

    class_methods do
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
