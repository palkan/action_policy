# frozen_string_literal: true

module ActionPolicy
  module LookupChain
    unless "".respond_to?(:safe_constantize)
      require "action_policy/ext/string_constantize"
      using ::ActionPolicy::Ext::StringConstantize
    end

    class << self
      attr_accessor :chain
      private :chain=

      def call(record, **opts)
        chain.each do |probe|
          val = probe.call(record, **opts)
          return val unless val.nil?
        end
        nil
      end
    end

    # By self `policy_class` method
    INSTANCE_POLICY_CLASS = ->(record, _) {
      record.policy_class if record.respond_to?(:policy_class)
    }

    # By record's class `policy_class` method
    CLASS_POLICY_CLASS = ->(record, _) {
      record.class.policy_class if record.class.respond_to?(:policy_class)
    }

    # Infer from class name
    INFER_FROM_CLASS = -> (record, _) {
      record_class = record.is_a?(::Class) ? record : record.class
      "#{record_class}Policy".safe_constantize
    }

    self.chain = [
      INSTANCE_POLICY_CLASS,
      CLASS_POLICY_CLASS,
      INFER_FROM_CLASS
    ]
  end
end
