# frozen_string_literal: true

require "action_policy/testing"

module ActionPolicy
  module RSpec
    module Matchers # :nodoc: all
      class BeAuthorizedTo < ::RSpec::Matchers::BuiltIn::BaseMatcher
        attr_reader :rule, :target, :policy, :actual_calls

        def initialize(rule, target)
          @rule = rule
          @target = target
        end

        def with(policy)
          @policy = policy
          self
        end

        def match(_expected, actual)
          raise "This matcher only supports block expectations" unless actual.is_a?(Proc)

          @policy ||= ::ActionPolicy.lookup(target)

          begin
            ActionPolicy::Testing::AuthorizeTracker.tracking { actual.call }
          rescue ActionPolicy::Unauthorized # rubocop: disable Lint/HandleExceptions
            # we don't want to care about authorization result
          end

          @actual_calls = ActionPolicy::Testing::AuthorizeTracker.calls

          actual_calls.any? { |call| call.matches?(policy, rule, target) }
        end

        def does_not_match?(*)
          raise "This matcher doesn't support negation"
        end

        def supports_block_expectations?
          true
        end

        def failure_message
          "expected #{formatted_record} " \
          "to be authorized with #{policy}##{rule}, " \
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
          actual_calls.map do |acall|
            " - #{acall.inspect}"
          end.join("\n")
        end

        def formatted_record(record = target)
          ::RSpec::Support::ObjectFormatter.format(record)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Module.new do
    def be_authorized_to(rule, target)
      ActionPolicy::RSpec::Matchers::BeAuthorizedTo.new(rule, target)
    end
  end)
end
