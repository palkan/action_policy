# frozen_string_literal: true

module ActionPolicy
  module Behaviours
    # Adds `policy_for` method
    module PolicyFor
      # Returns policy instance for the record.
      def policy_for(record: nil, with: nil, namespace: nil)
        namespace ||= authorization_namespace
        policy_class = with || ::ActionPolicy.lookup(record, namespace: namespace)
        policy_class.new(record, authorization_context)
      end

      def authorization_context
        raise NotImplementedError, "Please, define `authorization_context` method!"
      end

      def authorization_namespace
        # override to provide specific authorization namespace
      end
    end
  end
end
