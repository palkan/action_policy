# frozen_string_literal: true

module ActionPolicy
  module Policy
    # Adds rules aliases support and ability to specify
    # the default rule.
    #
    #   class ApplicationPolicy
    #     include ActionPolicy::Policy::Core
    #     prepend ActionPolicy::Policy::Aliases
    #
    #     # define which rule to use if `authorize!` called with
    #     # unknown rule
    #     default_rule :manage?
    #
    #     alias_rule :publish?, :unpublish?, to: :update?
    #   end
    #
    # Aliases are used only during `authorize!` call (and do not act like _real_ aliases).
    #
    # Aliases useful when combined with `CachedApply` (since we can cache only the target rule).
    module Aliases
      DEFAULT = :__default__

      class << self
        def prepended(base)
          base.extend ClassMethods
          base.prepend InstanceMethods
        end

        alias included prepended
      end

      module InstanceMethods # :nodoc:
        def resolve_rule(activity)
          return activity if respond_to?(activity)
          self.class.lookup_alias(activity) || super
        end
      end

      module ClassMethods # :nodoc:
        def default_rule(val)
          rules_aliases[DEFAULT] = val
        end

        def alias_rule(*rules, to:)
          rules.each do |rule|
            rules_aliases[rule] = to
          end
        end

        def lookup_alias(rule)
          rules_aliases.fetch(rule, rules_aliases[DEFAULT])
        end

        def rules_aliases
          return @rules_aliases if instance_variable_defined?(:@rules_aliases)

          @rules_aliases =
            if superclass.respond_to?(:rules_aliases)
              superclass.rules_aliases.dup
            else
              {}
            end
        end
      end
    end
  end
end
