# frozen_string_literal: true

module ActionPolicy
  module Behaviours
    # Adds `policy_for` method
    module PolicyFor
      # Returns policy instance for the record.
      def policy_for(record:, with: nil, namespace: nil, context: nil, **options)
        namespace ||= authorization_namespace
        policy_class = with || ::ActionPolicy.lookup(record, namespace: namespace, **options)
        policy_class&.new(record, authorization_context.tap { |ctx| ctx.merge!(context) if context })
      end

      def authorization_context
        raise NotImplementedError, "Please, define `authorization_context` method!"
      end

      def authorization_namespace
        # override to provide specific authorization namespace
      end

      # Override this method to provide implicit authorization target
      # that would be used in case `record` is not specified in
      # `authorize!` and `allowed_to?` call.
      #
      # It is also used to infer a policy for scoping (in `authorized_scope` method).
      def implicit_authorization_target
        # no-op
      end
    end
  end
end
