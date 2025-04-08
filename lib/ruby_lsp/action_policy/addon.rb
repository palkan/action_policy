# frozen_string_literal: true

# From https://gist.github.com/skryukov/35539d57b51f38235faaace2c1a2c1a1

require "active_support/inflector"

module RubyLsp
  module ActionPolicy
    class Addon < ::RubyLsp::Addon
      def name
        "ActionPolicy"
      end

      def activate(global_state, outgoing_queue)
        require "action_policy"
        warn "[ActionPolicy] Activating Ruby LSP addon v#{::ActionPolicy::VERSION}"
      end

      def deactivate
      end

      def create_definition_listener(response_builder, node_context, uri, dispatcher)
        Definition.new(response_builder, node_context, uri, dispatcher)
      end
    end

    class Definition
      include Requests::Support::Common
      include ActiveSupport::Inflector

      POLICY_SUPERCLASSES = ["ApplicationPolicy", "ActionPolicy::Base"].freeze

      def initialize(response_builder, uri, node_context, dispatcher)
        @response_builder = response_builder
        @node_context = node_context
        @uri = uri
        @path = uri.to_standardized_path
        @policy_rules_cache = {}

        dispatcher.register(self, :on_symbol_node_enter)
      end

      def on_symbol_node_enter(node)
        return unless in_authorize_call?

        target = @node_context.call_node
        # authorization target is the first argument (if explicit)
        policy_class = find_policy_class(target.arguments&.child_node&.first)
        return unless policy_class

        policy_path = find_policy_file(policy_class)
        return unless policy_path

        ensure_policy_rules_cached(policy_path)
        add_definition(policy_path, node.value)
      end

      private

      def in_authorize_call?
        call = @node_context.call_node
        call.is_a?(Prism::CallNode) && call.message == "authorize!"
      end

      def find_policy_class(target)
        content = File.read(@path)
        document = Prism.parse(content)
        class_node = find_containing_class(document.value)
        return derive_policy_from_target(target) unless class_node

        class_name = class_node.constant_path.slice
        return unless class_name.end_with?("Controller", "Channel")

        resource_name = class_name
          .delete_suffix("Controller")
          .delete_suffix("Channel")
          .singularize
        "#{resource_name}Policy"
      end

      def find_containing_class(root)
        return unless root.respond_to?(:statements)

        root.statements.body.find do |node|
          node.is_a?(Prism::ClassNode) &&
            node.constant_path.slice.end_with?("Controller", "Channel")
        end
      end

      def derive_policy_from_target(target)
        target_name = case target
        when Prism::InstanceVariableReadNode
          target.name.to_s[1..].classify
        when Prism::ConstantReadNode
          target.name.to_s
        when NilClass
          return
        else
          target.slice
        end

        target_name.end_with?("Policy") ? target_name : "#{target_name}Policy"
      end

      def find_policy_file(policy_class)
        file_path = policy_class.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase
        root_path = Dir.pwd

        [
          File.join(root_path, "app/policies/#{file_path}.rb"),
          File.join(root_path, "app/policies/#{file_path}_policy.rb"),
          *Dir.glob(File.join(root_path, "app/policies/**/#{file_path}.rb")),
          *Dir.glob(File.join(root_path, "app/policies/**/#{file_path}_policy.rb"))
        ].find { |path| File.exist?(path) }
      end

      def ensure_policy_rules_cached(policy_path)
        return if @policy_rules_cache[policy_path]

        content = File.read(policy_path)
        document = Prism.parse(content)

        document.value.statements.body.each do |stmt|
          if stmt.is_a?(Prism::ClassNode)
            @policy_rules_cache[policy_path] = extract_rules(stmt)
            break
          end
        end
      end

      def extract_rules(node)
        return {} unless node.body

        rules = {}
        private_section = false

        node.body.child_nodes.each do |stmt|
          case stmt
          when Prism::CallNode
            if stmt.message == "private"
              private_section = true
            elsif stmt.message == "alias_rule" && stmt.arguments&.arguments
              stmt.arguments.arguments
                .select { |arg| arg.is_a?(Prism::SymbolNode) }
                .each { |arg| rules[arg.value] ||= stmt.location.start_line }
            end
          when Prism::DefNode
            next if private_section
            rules[stmt.name.to_s] = stmt.location.start_line
          end
        end
        rules
      end

      def add_definition(policy_path, action)
        rules = @policy_rules_cache[policy_path]
        line_number = rules&.[](action.to_s)
        return unless line_number

        @response_builder << Interface::Location.new(
          uri: URI::Generic.from_path(path: policy_path).to_s,
          range: Interface::Range.new(
            start: Interface::Position.new(line: line_number - 1, character: 0),
            end: Interface::Position.new(line: line_number - 1, character: 0)
          )
        )
      end
    end
  end
end
