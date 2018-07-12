# frozen_string_literal: true

module ActionPolicy
  class UnknownScopeType < Error # :nodoc:
    MESSAGE_TEMPLATE = "Unknown policy scope type: %s"

    attr_reader :message

    def initialize(type)
      @message = MESSAGE_TEMPLATE % type
    end
  end

  class UnknownNamedScope < Error # :nodoc:
    MESSAGE_TEMPLATE = "Unknown named scope :%s for type :%s"

    attr_reader :message

    def initialize(type, name)
      @message = format(MESSAGE_TEMPLATE, name, type)
    end
  end

  module Policy
    # Scoping is used to modify the _objects under authorization_.
    #
    # The most common situation is when you want to _scope_ the collection depending
    # on the current user permissions.
    #
    # For example:
    #
    #   class ApplicationPolicy < ActionPolicy::Base
    #     # Scoping only makes sense when you have the authorization context
    #     authorize :user
    #
    #     # :scope here is a scoping type
    #     authorized :scope do |relation|
    #       # authorization context is available within a scope
    #       if user.admin?
    #         relation
    #       else
    #         relation.publicly_visible
    #       end
    #     end
    #   end
    #
    #   base_scope = User.all
    #   authorized_scope = ApplicantPolicy.new(user: user)
    #    .apply_scope(base_scope, :scope)
    module Scoping
      class << self
        def included(base)
          base.extend ClassMethods
        end
      end

      # TODO: better API?
      def apply_scope(target, type, as: :default)
        raise ActionPolicy::UnknownScopeType, type unless
          self.class.scoping_handlers.key?(type)

        raise ActionPolicy::UnknownNamedScope.new(type, as) unless
          self.class.scoping_handlers[type].key?(as)

        send(:"__scoping__#{type}__#{as}", target)
      end

      module ClassMethods # :nodoc:
        # Register a new scoping method for the `type`
        # TODO: better naming; now it's confused with `authorize`
        def authorized(type, name = :default, &block)
          mid = :"__scoping__#{type}__#{name}"

          define_method(mid, &block)

          scoping_handlers[type][name] = mid
        end

        def scoping_handlers
          return @scoping_handlers if instance_variable_defined?(:@scoping_handlers)

          @scoping_handlers = Hash.new { |h, k| h[k] = {} }

          if superclass.respond_to?(:scoping_handlers)
            superclass.scoping_handlers.each do |k, v|
              @scoping_handlers[k] = v.dup
            end
          end

          @scoping_handlers
        end
      end
    end
  end
end
