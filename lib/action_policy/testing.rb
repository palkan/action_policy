# frozen_string_literal: true

module ActionPolicy
  # Testing utils
  module Testing
    # Collects all Authorizer calls
    module AuthorizeTracker
      class Call # :nodoc:
        attr_reader :policy, :rule

        def initialize(policy, rule)
          @policy = policy
          @rule = rule
        end

        def matches?(policy_class, actual_rule, target)
          policy_class == policy.class &&
            target == policy.record &&
            rule == actual_rule
        end

        def inspect
          "#{policy.record.inspect} was authorized with #{policy.class}##{rule}"
        end
      end

      class Scoping # :nodoc:
        attr_reader :policy, :type, :name, :scope_options

        def initialize(policy, type, name, scope_options)
          @policy = policy
          @type = type
          @name = name
          @scope_options = scope_options
        end

        def matches?(policy_class, actual_type, actual_name, actual_scope_options)
          policy_class == policy.class &&
            type == actual_type &&
            name == actual_name &&
            scope_options == actual_scope_options
        end

        def inspect
          "#{policy.class} :#{name} for :#{type} #{scope_options_message}"
        end

        private

        def scope_options_message
          if scope_options
            "with scope options #{scope_options}"
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
        def track_scope(_target, policy, type:, name:, scope_options:)
          return unless tracking?
          scopings << Scoping.new(policy, type, name, scope_options)
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

      def scopify(*args)
        AuthorizeTracker.track_scope(*args)
        super
      end
    end

    ActionPolicy::Authorizer.singleton_class.prepend(AuthorizerExt)
  end
end
