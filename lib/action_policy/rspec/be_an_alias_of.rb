# frozen_string_literal: true

require "action_policy/testing"

module ActionPolicy
  module RSpec
    # Policy rule alias matcher `be_an_alias_of`.
    #
    # Verifies that for given policy a policy rule has an alias.
    #
    # Example:
    #
    #   # in policy specs
    #   subject(:policy) { described_class.new(record, user: user) }
    #
    #   let(:user) { build_stubbed(:user) }
    #   let(:record) { build_stubbed(:post) }
    #
    #   describe "#show?" do
    #     it "is an alias of :index? policy rule" do
    #       expect(:show?).to be_an_alias_of(policy, :index?)
    #     end
    #   end
    #
    #   # negated version
    #   describe "#show?" do
    #     it "is not an alias of :index? policy rule" do
    #       expect(:show?).to_not be_an_alias_of(policy, :index?)
    #     end
    #   end
    #
    class BeAnAliasOf < ::RSpec::Matchers::BuiltIn::BaseMatcher
      attr_reader :policy, :rule, :actual

      def initialize(policy, rule)
        @policy = policy
        @rule = rule
      end

      def match(_expected, actual)
        policy.resolve_rule(actual) == rule
      end

      def does_not_match?(actual)
        @actual = actual
        policy.resolve_rule(actual) != rule
      end

      def supports_block_expectations?() = false

      def failure_message
        "expected #{policy}##{actual} " \
        "to be an alias of #{policy}##{rule}"
      end

      def failure_message_when_negated
        "expected #{policy}##{actual} " \
        "to not be an alias of #{policy}##{rule}"
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Module.new do
    def be_an_alias_of(policy, rule)
      ActionPolicy::RSpec::BeAnAliasOf.new(policy, rule)
    end
  end)
end
