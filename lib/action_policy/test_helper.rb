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
        "Registered authorizations: #{actual_calls.empty? ? 'none' : actual_calls.map(&:inspect).join(',')}"
      )
    end
  end
end

