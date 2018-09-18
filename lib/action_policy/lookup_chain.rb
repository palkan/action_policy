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

    # Cache namespace resolving result for policies.
    # @see benchmarks/namespaced_lookup_cache.rb
    class NamespaceCache
      class << self
        attr_reader :store

        def fetch(namespace, policy)
          return yield unless LookupChain.namespace_cache_enabled?
          return store[namespace][policy] if store[namespace].key?(policy)
          store[namespace][policy] ||= yield
        end

        def clear
          @store = Hash.new { |h, k| h[k] = {} }
        end
      end

      clear
    end

    class << self
      attr_accessor :chain, :namespace_cache_enabled

      alias namespace_cache_enabled? namespace_cache_enabled

      def call(record, **opts)
        chain.each do |probe|
          val = probe.call(record, opts)
          return val unless val.nil?
        end
        nil
      end

      private

      def lookup_within_namespace(record, namespace)
        policy_name = policy_class_name_for(record)
        NamespaceCache.fetch(namespace.name, policy_name) do
          mod = namespace

          loop do
            policy = "#{mod.name}::#{policy_name}".safe_constantize

            break policy unless policy.nil?

            mod = mod.namespace

            break if mod.nil?
          end
        end
      end

      def policy_class_name_for(record)
        return record.policy_name.to_s if record.respond_to?(:policy_name)

        record_class = record.is_a?(Module) ? record : record.class

        if record_class.respond_to?(:policy_name)
          record_class.policy_name.to_s
        else
          "#{record_class}Policy"
        end
      end
    end

    # Enable namespace cache by default or
    # if RACK_ENV provided and equal to "production"
    self.namespace_cache_enabled =
      !ENV["RACK_ENV"].nil? ? ENV["RACK_ENV"] == "production" : true

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
