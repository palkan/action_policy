# frozen_string_literal: true

module ActionPolicy
  module Policy
    # Adds rules aliases support and ability to specify
    # the default rule.
    #
    #   class ApplicationPolicy
    #     include ActionPolicy::Policy::Core
    #     include ActionPolicy::Policy::Aliases
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
        def included(base)
          base.extend ClassMethods
        end
      end

      def resolve_rule(activity)
        self.class.lookup_alias(activity) ||
          (activity if respond_to?(activity)) ||
          (check_rule_naming(activity) if ActionPolicy.enforce_predicate_rules_naming) ||
          self.class.lookup_default_rule ||
          super
      end

      private def check_rule_naming(activity)
        unless activity[-1] == "?"
          raise NonPredicateRule.new(self, activity)
        end
        nil
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

        def lookup_alias(rule) = rules_aliases[rule]

        def lookup_default_rule() = rules_aliases[DEFAULT]

        def rules_aliases
          return @rules_aliases if instance_variable_defined?(:@rules_aliases)

          @rules_aliases = if superclass.respond_to?(:rules_aliases)
            superclass.rules_aliases.dup
          else
            {}
          end
        end

        def method_added(name)
          rules_aliases.delete(name) if public_method_defined?(name)
        end
      end
    end
  end
end
