# frozen_string_literal: true

require "action_policy/utils/suggest_message"

require "action_policy/ext/proc_case_eq"

using ActionPolicy::Ext::ProcCaseEq

module ActionPolicy
  class UnknownScopeType < Error # :nodoc:
    include ActionPolicy::SuggestMessage

    MESSAGE_TEMPLATE = "Unknown policy scope type :%s for %s%s"

    attr_reader :message

    def initialize(policy_class, type)
      @message = format(
        MESSAGE_TEMPLATE,
        type, policy_class,
        suggest(type, policy_class.scoping_handlers.keys)
      )
    end
  end

  class UnknownNamedScope < Error # :nodoc:
    include ActionPolicy::SuggestMessage

    MESSAGE_TEMPLATE = "Unknown named scope :%s for type :%s for %s%s"

    attr_reader :message

    def initialize(policy_class, type, name)
      @message = format(
        MESSAGE_TEMPLATE, name, type, policy_class,
        suggest(name, policy_class.scoping_handlers[type].keys)
      )
    end
  end

  class UnrecognizedScopeTarget < Error # :nodoc:
    MESSAGE_TEMPLATE = "Couldn't infer scope type for %s instance"

    attr_reader :message

    def initialize(target)
      target_class = target.is_a?(Module) ? target : target.class

      @message = format(
        MESSAGE_TEMPLATE, target_class
      )
    end
  end

  module Policy
    # Scoping is used to modify the _object under authorization_.
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
    #     # :relation here is a scoping type
    #     scope_for :relation do |relation|
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
    #    .apply_scope(base_scope, type: :relation)
    module Scoping
      class << self
        def included(base)
          base.extend ClassMethods
        end
      end

      # Pass target to the scope handler of the specified type and name.
      # If `name` is not specified then `:default` name is used.
      # If `type` is not specified then we try to infer the type from the
      # target class.
      def apply_scope(target, type:, name: :default)
        raise ActionPolicy::UnknownScopeType.new(self.class, type) unless
          self.class.scoping_handlers.key?(type)

        raise ActionPolicy::UnknownNamedScope.new(self.class, type, name) unless
          self.class.scoping_handlers[type].key?(name)

        send(:"__scoping__#{type}__#{name}", target)
      end

      def resolve_scope_type(target)
        lookup_type_from_target(target) ||
          raise(ActionPolicy::UnrecognizedScopeTarget, target)
      end

      def lookup_type_from_target(target)
        self.class.scope_matchers.detect do |(_type, matcher)|
          matcher === target # rubocop:disable Style/CaseEquality
        end&.first
      end

      module ClassMethods # :nodoc:
        # Register a new scoping method for the `type`
        def scope_for(type, name = :default, &block)
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

        # Define scope type matcher.
        #
        # Scope matcher is an object that implements `#===` (_case equality_) or a Proc.
        #
        # When no type is provided when applying a scope we try to infer a type
        # from the target object by calling matchers one by one until we find a matching
        # type (i.e. there is a matcher which returns `true` when applying it to the target).
        def scope_matcher(type, class_or_proc)
          scope_matchers << [type, class_or_proc]
        end

        def scope_matchers
          return @scope_matchers if instance_variable_defined?(:@scope_matchers)

          @scope_matchers = []

          @scope_matchers = superclass.scope_matchers.dup if superclass.respond_to?(:scope_matchers)

          @scope_matchers
        end
      end
    end
  end
end
