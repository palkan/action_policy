# frozen_string_literal: true

require "active_support/concern"
require "action_policy/behaviour"

module ActionPolicy
  # Raised when `authorize!` hasn't been called for action
  class UnauthorizedAction < Error
    def initialize(controller, action)
      super("Action '#{controller}##{action}' hasn't been authorized")
    end
  end

  # Controller concern.
  # Add `authorize!` and `allowed_to?` methods,
  # provide `verify_authorized` hook.
  module Controller
    extend ActiveSupport::Concern

    include ActionPolicy::Behaviour
    include ActionPolicy::Behaviours::ThreadMemoized
    include ActionPolicy::Behaviours::Memoized
    include ActionPolicy::Behaviours::Namespaced

    included do
      if respond_to?(:helper_method)
        helper_method :allowed_to?
        helper_method :authorized_scope
        helper_method :allowance_to
      end

      attr_writer :authorize_count
      attr_reader :verify_authorized_skipped

      protected :authorize_count=, :authorize_count
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
    # @return the policy record
    # Raises `ActionPolicy::Unauthorized` if check failed.
    def authorize!(record = :__undef__, to: nil, **options)
      to ||= :"#{action_name}?"

      policy_record = super

      self.authorize_count += 1
      policy_record
    end

    # Tries to infer the resource class from controller name
    # (i.e. `controller_name.classify.safe_constantize`).
    def implicit_authorization_target
      controller_name&.classify&.safe_constantize
    end

    def verify_authorized
      Kernel.raise UnauthorizedAction.new(controller_path, action_name) if
        authorize_count.zero? && !verify_authorized_skipped
    end

    def authorize_count
      @authorize_count ||= 0
    end

    def skip_verify_authorized!
      @verify_authorized_skipped = true
    end

    class_methods do
      # Adds after_action callback to check that
      # authorize! method has been called.
      def verify_authorized(**options)
        after_action :verify_authorized, options
      end

      # Skips verify_authorized after_action callback.
      def skip_verify_authorized(**options)
        skip_after_action :verify_authorized, options
      end
    end
  end
end
