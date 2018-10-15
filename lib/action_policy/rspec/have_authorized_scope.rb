# frozen_string_literal: true

require "action_policy/testing"

module ActionPolicy
  module RSpec
    # Implements `have_authorized_scope` matcher.
    #
    # Verifies that a block of code applies authorization scoping using specific policy.
    #
    # Example:
    #
    #   # in controller/request specs
    #   subject { get :index }
    #
    #   it "has authorized scope" do
    #     expect { subject }
    #       .to have_authorized_scope(:active_record_relation)
    #       .with(ProductPolicy)
    #   end
    #
    class HaveAuthorizedScope < ::RSpec::Matchers::BuiltIn::BaseMatcher
      attr_reader :type, :name, :policy, :scope_options, :actual_scopes

      def initialize(type)
        @type = type
        @name = :default
        @scope_options = nil
      end

      def with(policy)
        @policy = policy
        self
      end

      def as(name)
        @name = name
        self
      end

      def with_scope_options(scope_options)
        @scope_options = scope_options
        self
      end

      def match(_expected, actual)
        raise "This matcher only supports block expectations" unless actual.is_a?(Proc)

        ActionPolicy::Testing::AuthorizeTracker.tracking { actual.call }

        @actual_scopes = ActionPolicy::Testing::AuthorizeTracker.scopings

        actual_scopes.any? { |scope| scope.matches?(policy, type, name, scope_options) }
      end

      def does_not_match?(*)
        raise "This matcher doesn't support negation"
      end

      def supports_block_expectations?
        true
      end

      def failure_message
        "expected a scoping named :#{name} for type :#{type} " \
        "#{scope_options_message} " \
        "from #{policy} to have been applied, " \
        "but #{actual_scopes_message}"
      end

      def scope_options_message
        if scope_options
          "with scope options #{scope_options}"
        else
          "without scope options"
        end
      end

      def actual_scopes_message
        if actual_scopes.empty?
          "no scopings have been made"
        else
          "the following scopings were encountered:\n" \
          "#{formatted_scopings}"
        end
      end

      def formatted_scopings
        actual_scopes.map do |ascope|
          " - #{ascope.inspect}"
        end.join("\n")
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Module.new do
    def have_authorized_scope(type) # rubocop:disable Naming/PredicateName
      ActionPolicy::RSpec::HaveAuthorizedScope.new(type)
    end
  end)
end
