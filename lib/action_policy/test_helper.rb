# frozen_string_literal: true

require "action_policy/testing"

module ActionPolicy
  # Provides assertions for policies usage
  module TestHelper
    class WithScopeTarget
      attr_reader :scopes

      def initialize(scopes)
        @scopes = scopes
      end

      def with_target
        if scopes.size > 1
          raise "Too many matching scopings (#{scopes.size}), " \
                "you can run `.with_target` only when there is the only one match"
        end

        yield scopes.first.target
      end
    end

    # Asserts that the given policy was used to authorize the given target.
    #
    #   def test_authorize
    #     assert_authorized_to(:show?, user, with: UserPolicy) do
    #       get :show, id: user.id
    #     end
    #   end
    #
    # You can omit the policy (then it would be inferred from the target):
    #
    #     assert_authorized_to(:show?, user) do
    #       get :show, id: user.id
    #     end
    #
    def assert_authorized_to(rule, target, with: nil, context: {})
      raise ArgumentError, "Block is required" unless block_given?

      policy = with || ::ActionPolicy.lookup(target)

      begin
        ActionPolicy::Testing::AuthorizeTracker.tracking { yield }
      rescue ActionPolicy::Unauthorized
        # we don't want to care about authorization result
      end

      actual_calls = ActionPolicy::Testing::AuthorizeTracker.calls

      assert(
        actual_calls.any? { |call| call.matches?(policy, rule, target, context) },
        "Expected #{target.inspect} to be authorized with #{policy}##{rule}, " \
        "#{context ? "and context #{context}, " : ""}" \
        "but no such authorization has been made.\n" \
        "Registered authorizations: " \
        "#{actual_calls.empty? ? "none" : actual_calls.map(&:inspect).join(",")}"
      )
    end

    # Asserts that the given policy was used for scoping.
    #
    #   def test_authorize
    #     assert_have_authorized_scope(type: :active_record_relation, with: UserPolicy) do
    #       get :index
    #     end
    #   end
    #
    # You can also specify `as` option.
    #
    # NOTE: `type` and `with` must be specified.
    #
    # You can run additional assertions for the matching target (the object passed
    # to the `authorized_scope` method) by calling `with_target`:
    #
    #   def test_authorize
    #     assert_have_authorized_scope(type: :active_record_relation, with: UserPolicy) do
    #       get :index
    #     end.with_target do |target|
    #       assert_equal User.all, target
    #     end
    #   end
    #
    def assert_have_authorized_scope(type:, with:, as: :default, scope_options: nil, context: {})
      raise ArgumentError, "Block is required" unless block_given?

      policy = with

      ActionPolicy::Testing::AuthorizeTracker.tracking { yield }

      actual_scopes = ActionPolicy::Testing::AuthorizeTracker.scopings

      scope_options_message = if scope_options
        "with scope options #{scope_options}"
      else
        "without scope options"
      end

      context_message = context.empty? ? "without context" : "with context: #{context}"

      assert(
        actual_scopes.any? { |scope| scope.matches?(policy, type, as, scope_options, context) },
        "Expected a scoping named :#{as} for :#{type} type " \
        "#{scope_options_message} " \
        "and #{context_message} " \
        "from #{policy} to have been applied, " \
        "but no such scoping has been made.\n" \
        "Registered scopings: " \
        "#{actual_scopes.empty? ? "none" : actual_scopes.map(&:inspect).join(",")}"
      )

      WithScopeTarget.new(actual_scopes)
    end
  end
end
