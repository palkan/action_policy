# frozen_string_literal: true

require "action_policy/testing"

module ActionPolicy
  module RSpec
    # Authorization matcher `be_authorized_to`.
    #
    # Verifies that a block of code has been authorized using specific policy.
    #
    # Example:
    #
    #   # in controller/request specs
    #   subject { patch :update, id: product.id }
    #
    #   it "is authorized" do
    #     expect { subject }
    #       .to be_authorized_to(:manage?, product)
    #       .with(ProductPolicy)
    #   end
    #
    class BeAuthorizedTo < ::RSpec::Matchers::BuiltIn::BaseMatcher
      attr_reader :rule, :target, :policy, :actual_calls, :context

      def initialize(rule, target)
        @rule = rule
        @target = target
      end

      def with(policy)
        @policy = policy
        self
      end

      def with_context(context)
        @context = context
        self
      end

      def match(_expected, actual)
        raise "This matcher only supports block expectations" unless actual.is_a?(Proc)

        @policy ||= ::ActionPolicy.lookup(target)
        @context ||= nil

        begin
          ActionPolicy::Testing::AuthorizeTracker.tracking { actual.call }
        rescue ActionPolicy::Unauthorized
          # we don't want to care about authorization result
        end

        @actual_calls = ActionPolicy::Testing::AuthorizeTracker.calls

        actual_calls.any? { _1.matches?(policy, rule, target, context) }
      end

      def does_not_match?(*)
        raise "This matcher doesn't support negation"
      end

      def supports_block_expectations?() = true

      def failure_message
        "expected #{formatted_record} " \
        "to be authorized with #{policy}##{rule}, " \
        "#{context ? "and context #{context.inspect}, " : ""}" \
        "but #{actual_calls_message}"
      end

      def actual_calls_message
        if actual_calls.empty?
          "no authorization calls have been made"
        else
          "the following calls were encountered:\n" \
          "#{formatted_calls}"
        end
      end

      def formatted_calls
        actual_calls.map do
          " - #{_1.inspect}"
        end.join("\n")
      end

      def formatted_record(record = target) = ::RSpec::Support::ObjectFormatter.format(record)
    end
  end
end

RSpec.configure do |config|
  config.include(Module.new do
    def be_authorized_to(rule, target)
      ActionPolicy::RSpec::BeAuthorizedTo.new(rule, target)
    end
  end)
end
