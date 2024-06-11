# frozen_string_literal: true

module ActionPolicy
  module Behaviours
    # Adds `policy_for` method
    module PolicyFor
      require "action_policy/ext/policy_cache_key"
      using ActionPolicy::Ext::PolicyCacheKey

      # Returns policy instance for the record.
      def policy_for(record:, with: nil, namespace: authorization_namespace, context: nil, allow_nil: false, default: default_authorization_policy_class, strict_namespace: authorization_strict_namespace)
        context = context ? build_authorization_context.merge(context) : authorization_context

        policy_class = with || ::ActionPolicy.lookup(
          record,
          namespace:, context:, allow_nil:, default:, strict_namespace:
        )
        policy_class&.new(record, **context)
      end

      def authorization_context = @authorization_context ||= build_authorization_context

      def build_authorization_context
        Kernel.raise NotImplementedError, "Please, define `build_authorization_context` method!"
      end

      def authorization_namespace
        # override to provide specific authorization namespace
      end

      def default_authorization_policy_class
        # override to provide a policy class use when no policy found
      end

      def authorization_strict_namespace
        # override to provide strict namespace lookup option
      end

      # Override this method to provide implicit authorization target
      # that would be used in case `record` is not specified in
      # `authorize!` and `allowed_to?` call.
      #
      # It is also used to infer a policy for scoping (in `authorized_scope` method).
      def implicit_authorization_target
        # no-op
      end

      # Return implicit authorization target or raises an exception if it's nil
      def implicit_authorization_target!
        implicit_authorization_target || Kernel.raise(
          NotFound,
          [
            self,
            "Couldn't find implicit authorization target " \
            "for #{self.class}. " \
            "Please, provide policy class explicitly using `with` option or " \
            "define the `implicit_authorization_target` method."
          ]
        )
      end

      def policy_for_cache_key(record:, with: nil, namespace: nil, context: authorization_context, **)
        record_key = record._policy_cache_key(use_object_id: true)
        context_key = context.values.map { _1._policy_cache_key(use_object_id: true) }.join(".")

        "#{namespace}/#{with}/#{context_key}/#{record_key}"
      end
    end
  end
end
