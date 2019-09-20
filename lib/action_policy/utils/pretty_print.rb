# frozen_string_literal: true

old_verbose = $VERBOSE

begin
  require "method_source"
  # Ignore parse warnings when patch
  # Ruby version mismatches
  $VERBOSE = nil
  require "parser/current"
  require "unparser"
rescue LoadError
  # do nothing
ensure
  $VERBOSE = old_verbose
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
    TRUE =  "\e[32mtrue\e[0m"
    FALSE = "\e[31mfalse\e[0m"

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
        "#{expression} #=> #{colorize(eval_exp(expression))}"
      end

      def eval_exp(exp)
        return "<skipped>" if ignore_exp?(exp)
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

      def visit_begin(ast)
        #  Parens
        if ast.children.size == 1
          lines << indented("(")
          self.indent += 2
          visit_node(ast.children[0])
          self.indent -= 2
          lines << indented(")")
        else
          # Multiple expressions
          ast.children.each do |node|
            visit_node(node)
            # restore indent after each expression
            self.indent -= 2
          end
        end
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
        exp.match?(/^\s*binding\.(pry|irb)\s*$/)
      end

      def colorize(val)
        return val unless $stdout.isatty
        return TRUE if val.eql?(true)
        return FALSE if val.eql?(false)
        val
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
