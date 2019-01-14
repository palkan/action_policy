# frozen_string_literal: true

module ActionPolicy
  module RSpec # :nodoc: all
    module DSL
      def describe_rule(rule, *args, **kwargs)
        describe("##{rule}", *args, **kwargs) do
          subject { policy.apply(rule) }

          instance_eval(&Proc.new) if block_given?
        end
      end

      def succeed(*args)
        context(*args) do
          instance_eval(&Proc.new) if block_given?

          it "succeeds" do
            is_expected.to eq true
          end
        end
      end

      def failed(*args)
        context(*args) do
          instance_eval(&Proc.new) if block_given?

          it "fails" do
            is_expected.to eq false
          end
        end
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
