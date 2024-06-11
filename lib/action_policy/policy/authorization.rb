# frozen_string_literal: true

module ActionPolicy
  class AuthorizationContextMissing < Error # :nodoc:
    MESSAGE_TEMPLATE = "Missing policy authorization context: %s"

    attr_reader :message

    def initialize(id)
      @message = MESSAGE_TEMPLATE % id
    end
  end

  module Policy
    # Authorization context could include multiple parameters.
    #
    # It is possible to provide more verificatio contexts, by specifying them in the policy and
    # providing them at the authorization step.
    #
    # For example:
    #
    #   class ApplicationPolicy < ActionPolicy::Base
    #     # Add user and account to the context; it's required to be passed
    #     # to a policy constructor and be not nil
    #     authorize :user, :account
    #
    #     # you can skip non-nil check if you want
    #     # authorize :account, allow_nil: true
    #
    #     def manage?
    #       # available as a simple accessor
    #       account.enabled?
    #     end
    #   end
    #
    #   ApplicantPolicy.new(user: user, account: account)
    module Authorization
      class << self
        def included(base)
          base.extend ClassMethods
        end
      end

      attr_reader :authorization_context
      alias_method :build_authorization_context, :authorization_context

      def initialize(record = nil, **params)
        super(record)

        @authorization_context = {}

        self.class.authorization_targets.each do |id, opts|
          raise AuthorizationContextMissing, id unless params.key?(id) || opts[:optional]

          val = params.fetch(id, nil)

          raise AuthorizationContextMissing, id if val.nil? && opts[:allow_nil] != true

          authorization_context[id] = instance_variable_set("@#{id}", val)
        end

        authorization_context.freeze
      end

      module ClassMethods # :nodoc:
        def authorize(*ids, allow_nil: false, optional: false)
          allow_nil ||= optional

          ids.each do |id|
            authorization_targets[id] = {allow_nil:, optional:}
          end

          attr_reader(*ids)
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
end
