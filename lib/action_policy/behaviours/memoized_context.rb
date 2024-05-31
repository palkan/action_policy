# frozen_string_literal: true

module ActionPolicy
  module Behaviours
    # Per-instance memoization for policies.
    #
    # Used by `policy_for` to re-use policy object for records.
    #
    # Example:
    #
    #   include ActionPolicy::Behaviour
    #   include ActionPolicy::MemoizedContext
    #
    module MemoizedContext
      class << self
        def prepended(base)
          base.prepend InstanceMethods
        end

        alias_method :included, :prepended
      end

      module InstanceMethods # :nodoc:
        def authorization_context
          @_authorization_context ||= super
        end

        private def context_for_policy(context)
          return authorization_context if context.nil?

          if instance_variable_defined?(:@_authorization_context)
            authorization_context_was = authorization_context
            remove_instance_variable :@_authorization_context

            authorization_context.merge(context).tap do
              @_authorization_context = authorization_context_was
            end
          else
            authorization_context.merge(context).tap do
              remove_instance_variable :@_authorization_context
            end
          end
        end
      end
    end
  end
end
