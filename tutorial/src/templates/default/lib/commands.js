import { createRackServer } from "./server.js";
import IRBRepl from "./irb.js";

export default class ExternalCommands {
  constructor() {
    this.command = undefined;
  }

  server(port) {
    this.command = async function(vm) {
      const server = await createRackServer(vm, {skipRackup: true});

      server.listen(port, () => {
        console.log(`Express.js server started on port ${port}`);
        console.log(`Use Ctrl-C to stop`);
      });

      // FIXME: doesn't work; do WebContainers/jsh support signals at all?
      process.on('exit', async () => {
        console.log('Express.js server is shutting down');
        await vm.evalAsync(`execute_at_exit_hooks`)
      });
    }
  }

  console() {
    this.command = async function(vm) {
      const irb = new IRBRepl(vm);
      return irb.start();
    }
  }

  // Invokes a registered command if any
  invoke(vm) {
    if (!this.command) return;

    return this.command(vm);
  }
}
