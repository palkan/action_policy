# frozen_string_literal: true

module ActionPolicy
  # Testing utils
  module Testing
    # Collects all Authorizer calls
    module AuthorizeTracker
      module Context
        private

        def context_matches?(context, actual)
          return true unless context

          context === actual || actual >= context
        end
      end

      class Call # :nodoc:
        include Context

        attr_reader :policy, :rule

        def initialize(policy, rule)
          @policy = policy
          @rule = rule
        end

        def matches?(policy_class, actual_rule, target, context)
          policy_class == policy.class &&
            (target.is_a?(Class) ? target == policy.record : target === policy.record) &&
            rule == actual_rule && context_matches?(context, policy.authorization_context)
        end

        def inspect
          "#{policy.record.inspect} was authorized with #{policy.class}##{rule} " \
            "and context #{policy.authorization_context.inspect}"
        end
      end

      class Scoping # :nodoc:
        include Context

        attr_reader :policy, :target, :type, :name, :scope_options

        def initialize(policy, target, type, name, scope_options)
          @policy = policy
          @target = target
          @type = type
          @name = name
          @scope_options = scope_options
        end

        def matches?(policy_class, actual_type, actual_name, actual_scope_options, actual_context)
          policy_class == policy.class &&
            type == actual_type &&
            name == actual_name &&
            actual_scope_options === scope_options &&
            context_matches?(actual_context, policy.authorization_context)
        end

        def inspect
          "#{policy.class} :#{name} for :#{type} #{scope_options_message}"
        end

        private

        def scope_options_message
          if scope_options
            if defined?(::RSpec::Matchers::Composable) &&
                scope_options.is_a?(::RSpec::Matchers::Composable)
              "with scope options #{scope_options.description}"
            else
              "with scope options #{scope_options}"
            end
          else
            "without scope options"
          end
        end
      end

      class << self
        # Wrap code under inspection into this method
        # to track authorize! calls
        def tracking
          calls.clear
          scopings.clear
          Thread.current[:__action_policy_tracking] = true
          yield
        ensure
          Thread.current[:__action_policy_tracking] = false
        end

        # Called from Authorizer
        def track(policy, rule)
          return unless tracking?
          calls << Call.new(policy, rule)
        end

        # Called from Authorizer
        def track_scope(target, policy, type:, name:, scope_options:)
          return unless tracking?
          scopings << Scoping.new(policy, target, type, name, scope_options)
        end

        def calls
          Thread.current[:__action_policy_calls] ||= []
        end

        def scopings
          Thread.current[:__action_policy_scopings] ||= []
        end

        def tracking?
          Thread.current[:__action_policy_tracking] == true
        end
      end
    end

    # Extend authorizer to add tracking functionality
    module AuthorizerExt
      def call(*args)
        AuthorizeTracker.track(*args)
        super
      end

      def scopify(*args, **kwargs)
        AuthorizeTracker.track_scope(*args, **kwargs)
        super
      end
    end

    ActionPolicy::Authorizer.singleton_class.prepend(AuthorizerExt)
  end
end
