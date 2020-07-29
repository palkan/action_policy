# frozen_string_literal: true

module ActionPolicy
  module RSpec # :nodoc: all
    module DSL
      %w[describe fdescribe xdescribe].each do |meth|
        class_eval <<~CODE, __FILE__, __LINE__ + 1
          def #{meth}_rule(rule, *args, &block)
            find_and_eval_shared("context", "action_policy:policy_rule_context", caller.first, rule, *args, method: :#{meth}, block: block)
          end
        CODE
      end

      ["", "f", "x"].each do |prefix|
        class_eval <<~CODE, __FILE__, __LINE__ + 1
          def #{prefix}succeed(msg = "succeeds", *args, **kwargs, &block)
            the_caller = caller
            #{prefix}context(msg, *args, **kwargs) do
              instance_eval(&block) if block_given?
              find_and_eval_shared("examples", "action_policy:policy_rule_example", the_caller.first, true, the_caller)
            end
          end

          def #{prefix}failed(msg = "fails", *args, **kwargs, &block)
            the_caller = caller
            #{prefix}context(msg, *args, **kwargs) do
              instance_eval(&block) if block_given?
              find_and_eval_shared("examples", "action_policy:policy_rule_example", the_caller.first, false, the_caller)
            end
          end
        CODE
      end
    end

    module PolicyExampleGroup
      def self.included(base)
        base.metadata[:type] = :policy
        base.extend ActionPolicy::RSpec::DSL
        super
      end

      def formatted_policy(policy)
        "#{policy.result.inspect}\n#{policy.inspect_rule(policy.result.rule)}"
      end
    end
  end
end

if defined?(::RSpec)
  ::RSpec.shared_context "action_policy:policy_context" do
    let(:record) { nil }
    let(:context) { {} }
    let(:policy) { described_class.new(record, **context) }
  end

  ::RSpec.shared_context "action_policy:policy_rule_context" do |policy_rule, *args, method: "describe", block: nil|
    public_send(method, policy_rule.to_s, *args) do
      let(:rule) { policy_rule }

      let(:subject) do
        policy.apply(rule)
        policy.result
      end

      instance_eval(&block) if block
    end
  end

  ::RSpec.shared_examples_for "action_policy:policy_rule_example" do |success, the_caller|
    if success
      specify "is allowed" do
        next if subject.success?
        raise(
          RSpec::Expectations::ExpectationNotMetError,
          "Expected to succeed but failed:\n#{formatted_policy(policy)}",
          the_caller
        )
      end
    else
      specify "is denied" do
        next if subject.fail?
        raise(
          RSpec::Expectations::ExpectationNotMetError,
          "Expected to fail but succeed:\n#{formatted_policy(policy)}",
          the_caller
        )
      end
    end
  end

  ::RSpec.configure do |config|
    config.include(
      ActionPolicy::RSpec::PolicyExampleGroup,
      type: :policy,
      file_path: %r{spec/policies}
    )
    config.include_context(
      "action_policy:policy_context",
      type: :policy,
      file_path: %r{spec/policies}
    )
  end
end
