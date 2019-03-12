# frozen_string_literal: true

module ActionPolicy
  module RSpec # :nodoc: all
    module DSL
      %w[describe fdescribe xdescribe].each do |meth|
        class_eval <<~CODE, __FILE__, __LINE__ + 1
          def #{meth}_rule(policy_rule, *args, **kwargs)
            #{meth}("#\#{policy_rule}", *args, **kwargs) do
              let(:rule) { policy_rule }

              subject do
                policy.apply(rule)
                policy.result
              end

              instance_eval(&Proc.new) if block_given?
            end
          end
        CODE
      end

      ["", "f", "x"].each do |prefix|
        class_eval <<~CODE, __FILE__, __LINE__ + 1
          def #{prefix}succeed(*args, **kwargs)
            context(*args) do
              instance_eval(&Proc.new) if block_given?
              #{prefix}it "succeeds", kwargs do
                is_expected.to be_success, "Expected succeed but failed: \#{policy.result.inspect}"
              end
            end
          end

          def #{prefix}failed(*args, **kwargs)
            context(*args) do
              instance_eval(&Proc.new) if block_given?
              #{prefix}it "fails", kwargs do
                is_expected.to be_fail, "Expected to fail but succeed: \#{policy.result.inspect}"
              end
            end
          end
        CODE
      end
    end

    module PolicyExampleGroup
      def self.included(base)
        base.metadata[:type] = :policy
        base.extend ActionPolicy::RSpec::DSL
        base.let(:record) { nil }
        base.let(:policy) { described_class.new(record, context) }
        super
      end
    end
  end
end

if defined?(::RSpec)
  RSpec.configure do |config|
    config.include(
      ActionPolicy::RSpec::PolicyExampleGroup,
      type: :policy,
      file_path: %r{spec/policies}
    )
  end
end
