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

    require "action_policy/ext/symbol_camelize"
    using ActionPolicy::Ext::SymbolCamelize

    require "action_policy/ext/module_namespace"
    using ActionPolicy::Ext::ModuleNamespace

    # Cache namespace resolving result for policies.
    # @see benchmarks/namespaced_lookup_cache.rb
    class NamespaceCache
      class << self
        attr_reader :store

        def put_if_absent(scope, namespace, policy)
          local_store = store[scope][namespace]
          return local_store[policy] if local_store[policy]
          local_store[policy] ||= yield
        end

        def fetch(namespace, policy, strict:, &block)
          return yield unless LookupChain.namespace_cache_enabled?

          if strict
            put_if_absent(:strict, namespace, policy, &block)
          else
            put_if_absent(:flexible, namespace, policy, &block)
          end
        end

        def clear
          hash = Hash.new { |h, k| h[k] = {} }
          @store = {strict: hash, flexible: hash.clone}
        end
      end

      clear
    end

    class << self
      attr_accessor :chain, :namespace_cache_enabled

      alias_method :namespace_cache_enabled?, :namespace_cache_enabled

      def call(record, **opts)
        chain.each do |probe|
          val = probe.call(record, **opts)
          return val unless val.nil?
        end
        nil
      end

      private

      def lookup_within_namespace(policy_name, namespace, strict: false)
        NamespaceCache.fetch(namespace&.name || "Kernel", policy_name, strict: strict) do
          mod = namespace
          policy_class = nil

          loop do
            policy_class = [mod&.name, policy_name].compact.join("::").safe_constantize
            break policy_class if policy_class || mod.nil?

            mod = mod.namespace
          end

          next policy_class if !strict || namespace.nil? || policy_class.nil?

          # If we're in the strict mode and the namespace boundary is provided,
          # we must check that the found policy satisfies it
          policy_class if policy_class.name.start_with?("#{namespace.name}::")
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
      (!ENV["RACK_ENV"].nil?) ? ENV["RACK_ENV"] == "production" : true

    # By self `policy_class` method
    INSTANCE_POLICY_CLASS = ->(record, **) {
      record.policy_class if record.respond_to?(:policy_class)
    }

    # By record's class `policy_class` method
    CLASS_POLICY_CLASS = ->(record, **) {
      record.class.policy_class if record.class.respond_to?(:policy_class)
    }

    # Infer from class name
    INFER_FROM_CLASS = ->(record, namespace: nil, strict_namespace: false, **) {
      policy_name = policy_class_name_for(record)
      lookup_within_namespace(policy_name, namespace, strict: strict_namespace)
    }

    # Infer from passed symbol
    SYMBOL_LOOKUP = ->(record, namespace: nil, strict_namespace: false, **) {
      next unless record.is_a?(Symbol)

      policy_name = "#{record.camelize}Policy"
      lookup_within_namespace(policy_name, namespace, strict: strict_namespace)
    }

    # (Optional) Infer using String#classify if available
    CLASSIFY_SYMBOL_LOOKUP = ->(record, namespace: nil, strict_namespace: false, **) {
      next unless record.is_a?(Symbol)

      policy_name = "#{record.to_s.classify}Policy"
      lookup_within_namespace(policy_name, namespace, strict: strict_namespace)
    }

    self.chain = [
      SYMBOL_LOOKUP,
      (CLASSIFY_SYMBOL_LOOKUP if String.method_defined?(:classify)),
      INSTANCE_POLICY_CLASS,
      CLASS_POLICY_CLASS,
      INFER_FROM_CLASS
    ].compact
  end
end
