# frozen_string_literal: true

require "action_policy/testing"

module ActionPolicy
  # Provides assertions for policies usage
  module TestHelper
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
    # rubocop: disable Metrics/MethodLength
    def assert_authorized_to(rule, target, with: nil)
      raise ArgumentError, "Block is required" unless block_given?

      policy = with || ::ActionPolicy.lookup(target)

      begin
        ActionPolicy::Testing::AuthorizeTracker.tracking { yield }
      rescue ActionPolicy::Unauthorized # rubocop: disable Lint/HandleExceptions
        # we don't want to care about authorization result
      end

      actual_calls = ActionPolicy::Testing::AuthorizeTracker.calls

      assert(
        actual_calls.any? { |call| call.matches?(policy, rule, target) },
        "Expected #{target.inspect} to be authorized with #{policy}##{rule}, " \
        "but no such authorization has been made.\n" \
        "Registered authorizations: " \
        "#{actual_calls.empty? ? 'none' : actual_calls.map(&:inspect).join(',')}"
      )
    end
    # rubocop: enable Metrics/MethodLength

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
    # rubocop: disable Metrics/MethodLength
    def assert_have_authorized_scope(type:, with:, as: :default)
      raise ArgumentError, "Block is required" unless block_given?

      policy = with

      ActionPolicy::Testing::AuthorizeTracker.tracking { yield }

      actual_scopes = ActionPolicy::Testing::AuthorizeTracker.scopings

      assert(
        actual_scopes.any? { |scope| scope.matches?(policy, type, as) },
        "Expected a scoping named :#{as} for :#{type} type from #{policy} to have been applied, " \
        "but no such scoping has been made.\n" \
        "Registered scopings: " \
        "#{actual_scopes.empty? ? 'none' : actual_scopes.map(&:inspect).join(',')}"
      )
    end
    # rubocop: enable Metrics/MethodLength
  end
end
