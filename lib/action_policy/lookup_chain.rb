# frozen_string_literal: true

module ActionPolicy
  # LookupChain contains _resolvers_ to determine a policy
  # for a record (with additional options).
  #
  # You can modify the `LookupChain.chain` (for example, to add
  # custom resolvers).
  module LookupChain
    unless "".respond_to?(:safe_constantize)
      require "action_policy/ext/string_constantize"
      using ActionPolicy::Ext::StringConstantize
    end

    require "action_policy/ext/module_namespace"
    using ActionPolicy::Ext::ModuleNamespace

    class << self
      attr_accessor :chain

      def call(record, **opts)
        chain.each do |probe|
          val = probe.call(record, **opts)
          return val unless val.nil?
        end
        nil
      end

      private

      def lookup_within_namespace(record, namespace)
        policy_name = policy_class_name_for(record)
        mod = namespace
        loop do
          return mod.const_get(policy_name, false) if
            mod.const_defined?(policy_name, false)

          mod = mod.namespace

          return if mod.nil?
        end
      end

      def policy_class_name_for(record)
        record_class = record.is_a?(Class) ? record : record.class

        if record_class.respond_to?(:policy_name)
          record_class.policy_name.to_s
        else
          "#{record_class}Policy"
        end
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

    # Lookup within namespace when provided
    NAMESPACE_LOOKUP = ->(record, namespace: nil, **) {
      next if namespace.nil?

      lookup_within_namespace(record, namespace)
    }

    # Infer from class name
    INFER_FROM_CLASS = ->(record, _) {
      policy_class_name_for(record).safe_constantize
    }

    self.chain = [
      INSTANCE_POLICY_CLASS,
      CLASS_POLICY_CLASS,
      NAMESPACE_LOOKUP,
      INFER_FROM_CLASS
    ]
  end
end
