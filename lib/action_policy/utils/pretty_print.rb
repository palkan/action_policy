# frozen_string_literal: true

old_verbose = $VERBOSE

begin
  require "method_source"
  # Ignore parse warnings when patch
  # Ruby version mismatches
  $VERBOSE = nil
  require "prism"
rescue LoadError
  # do nothing
ensure
  $VERBOSE = old_verbose
end

module ActionPolicy
  using RubyNext

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
    TRUE = "\e[32mtrue\e[0m"
    FALSE = "\e[31mfalse\e[0m"

    class Visitor
      attr_reader :lines, :object, :source
      attr_accessor :indent

      def initialize(object)
        @object = object
      end

      def collect(ast)
        @lines = []
        @indent = 0
        @source = ast.source.source
        ast = ast.value.child_nodes[0].child_nodes[0].body

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
        expression = source[sexp.location.start_offset...sexp.location.end_offset]
        "#{expression} #=> #{PrettyPrint.colorize(eval_exp(expression))}"
      end

      def eval_exp(exp)
        return "<skipped>" if ignore_exp?(exp)
        object.instance_eval(exp)
      rescue => e
        "Failed: #{e.message}"
      end

      def visit_and_node(ast)
        visit_node(ast.left)
        lines << indented("AND")
        visit_node(ast.right)
      end

      def visit_or_node(ast)
        visit_node(ast.left)
        lines << indented("OR")
        visit_node(ast.right)
      end

      def visit_statements_node(ast)
        ast.child_nodes.each do |node|
          visit_node(node)
          # restore indent after each expression
          self.indent -= 2
        end
      end

      def visit_parentheses_node(ast)
        lines << indented("(")
        self.indent += 2
        visit_node(ast.child_nodes[0])
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

      # Some lines should not be evaled
      def ignore_exp?(exp)
        PrettyPrint.ignore_expressions.any? { exp.match?(_1) }
      end
    end

    class << self
      attr_accessor :ignore_expressions

      if defined?(::Prism) && defined?(::MethodSource)
        def available?() = true

        def print_method(object, method_name)
          ast = Prism.parse(object.method(method_name).source)

          Visitor.new(object).collect(ast)
        end
      else
        def available?() = false

        def print_method(_, _) = ""
      end

      def colorize(val)
        return val unless $stdout.isatty
        return TRUE if val.eql?(true) # rubocop:disable Lint/DeprecatedConstants
        return FALSE if val.eql?(false) # rubocop:disable Lint/DeprecatedConstants
        val
      end
    end

    self.ignore_expressions = [
      /^\s*binding\.(pry|irb)\s*$/s
    ]
  end
end
