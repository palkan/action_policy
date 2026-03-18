import repl from "node:repl";

const isRecoverableError = (error) => {
  if (error.message.includes('SyntaxError')) {
    return true;
  }

  return false;
}

const rubyWriter = (output) => {
  if (!output) return;

  if (typeof output === 'string') {
    return output;
  }

  return output.toString().replace(/\n$/, "");
}

export default class IRBRepl {
  constructor(vm) {
    this.vm = vm;
    this.eval = this.eval.bind(this);
  }

  async eval (cmd, context, filename, callback) {
    let result;
    try {
      result = await this.vm.evalAsync(`
__code__ = <<~'RUBY'
${cmd}
RUBY

$irb.eval_code(__code__)
`);
    } catch (e) {
      if (e.message.includes('SystemExit')) {
        process.exit();
      }
      if (isRecoverableError(e)) {
        return callback(new repl.Recoverable(e));
      }

      return callback(null, e.message);
    }
    callback(null, result);
  }

  async start() {
    // Set up IRB
    const promptVal = await this.vm.evalAsync(`
      require "irb"

      STDOUT.sync = true
      if IRB.conf.empty?
        ap_path = __FILE__
        $0 = File::basename(ap_path, ".rb") if ap_path
        IRB.setup(ap_path)
      end

      class NonBlockingIO
        def gets
          raise NonImplementedError
        end

        def external_encoding
          "UTF-8"
        end

        def wait_readable(timeout = nil)
          true
        end

        def getc = "x"
        def ungetc(c) = nil
      end

      class IRB::Irb
        def eval_code(code)
          statement = parse_input(code)

          context.evaluate(statement, @line_no)
          @line_no += code.count("\n")
          context.inspect_last_value
        rescue SystemExit, SignalException, SyntaxError
          raise
        rescue Interrupt, Exception => exc
          handle_exception(exc)
          context.workspace.local_variable_set(:_, exc)
        end
      end

      $irb = IRB::Irb.new(nil, IRB::StdioInputMethod.new)

      # return configured prompt
      IRB.conf[:PROMPT][IRB.conf[:PROMPT_MODE]][:PROMPT_I]
        .gsub(/(%\\d+)?n/, "") # no line number support
        .then { $irb.send(:format_prompt, _1, nil, 0, 0) }
    `)

    const prompt = promptVal.toJS()
    const local = repl.start({prompt, eval: this.eval, writer: rubyWriter});

    local.on('exit', () => {
      // TODO: save history?
      process.exit();
    });
  }
}
