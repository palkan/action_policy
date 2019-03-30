# frozen_string_literal: true

begin
  require "method_source"
  require "parser/current"
  require "unparser"
rescue LoadError
  # do nothing
end

module ActionPolicy
  unless "".respond_to?(:then)
    require "action_policy/ext/yield_self_then"
    using ActionPolicy::Ext::YieldSelfThen
  end

  # Takes the object and a method name,
  # and returns the "annotated" source code for the method:
  # code is split into parts by logical operators and each
  # part is evaluated separately.
  #
  # Example:
  #
  #  class MyClass
  #    def access?
  #      admin? && access_feed?
  #    end
  #  end
  #
  #  puts PrettyPrint.format_method(MyClass.new, :access?)
  #
  #  #=> MyClass#access?
  #  #=> ↳ admin? #=> false
  #  #=> AND
  #  #=> access_feed? #=> true
  module PrettyPrint
    class Visitor
      attr_reader :lines, :object
      attr_accessor :indent

      def initialize(object)
        @object = object
      end

      def collect(ast)
        @lines = []
        @indent = 0

        visit_node(ast)

        lines.join("\n")
      end

      def visit_node(ast)
        if respond_to?("visit_#{ast.type}")
          send("visit_#{ast.type}", ast)
        else
          visit_missing ast
        end
      end

      def expression_with_result(sexp)
        expression = Unparser.unparse(sexp)
        "#{expression} #=> #{eval_exp(expression)}"
      end

      def eval_exp(exp)
        object.instance_eval(exp)
      rescue => e
        "Failed: #{e.message}"
      end

      def visit_and(ast)
        visit_node(ast.children[0])
        lines << indented("AND")
        visit_node(ast.children[1])
      end

      def visit_or(ast)
        visit_node(ast.children[0])
        lines << indented("OR")
        visit_node(ast.children[1])
      end

      # Parens
      def visit_begin(ast)
        lines << indented("(")
        self.indent += 2
        visit_node(ast.children[0])
        self.indent -= 2
        lines << indented(")")
      end

      def visit_missing(ast)
        lines << indented(expression_with_result(ast))
      end

      def indented(str)
        "#{indent.zero? ? "↳ " : ""}#{" " * indent}#{str}".tap do
          # increase indent after the first expression
          self.indent += 2 if indent.zero?
        end
      end
    end

    class << self
      if defined?(::Unparser) && defined?(::MethodSource)
        def available?
          true
        end

        def print_method(object, method_name)
          ast = object.method(method_name).source.then(&Unparser.method(:parse))
          # outer node is a method definition itself
          body = ast.children[2]

          Visitor.new(object).collect(body)
        end
      else
        def available?
          false
        end

        def print_method(_, _)
          ""
        end
      end
    end
  end
end
