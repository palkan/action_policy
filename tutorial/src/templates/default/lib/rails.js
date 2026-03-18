import { RubyVM } from "@ruby/wasm-wasi";
import { WASI } from "wasi";
import fs from "fs/promises";
import { PGLite4Rails } from "./database.js";

const rubyWasm = new URL("../node_modules/@ruby/wasm-wasi/dist/ruby.wasm", import.meta.url).pathname;

const railsRootDir = new URL("../workspace/store", import.meta.url).pathname;
const pgDataDir = new URL("../pgdata", import.meta.url).pathname;

export default async function initVM(vmopts = {}) {
  const { args, skipRails } = vmopts;
  const env = vmopts.env || {};
  const binary = await fs.readFile(rubyWasm);
  const module = await WebAssembly.compile(binary);

  const RAILS_ENV = env.RAILS_ENV || process.env.RAILS_ENV;
  if (RAILS_ENV) env.RAILS_ENV = RAILS_ENV;

  const workspaceDir = new URL("../workspace", import.meta.url).pathname;
  const workdir = process.cwd().startsWith(workspaceDir) ?
    `/workspace${process.cwd().slice(workspaceDir.length)}` :
    "";

  const cliArgs = args?.length ? ['ruby.wasm'].concat(args) : undefined;

  const wasi = new WASI(
    {
      env: {"RUBYOPT": "-EUTF-8 -W0", ...env},
      version: "preview1",
      returnOnExit: true,
      preopens: {
        "/workspace": workspaceDir
      },
      args: cliArgs
    }
  );

  const { vm } = await RubyVM.instantiateModule({
    module,
    wasip1: wasi,
    args: cliArgs
  });

  if (!skipRails) {
    const pglite = new PGLite4Rails(pgDataDir);
    global.pglite = pglite;

    const authenticationPatch = await fs.readFile(new URL("./patches/authentication.rb", import.meta.url).pathname, 'utf8');
    const appGeneratorPatch = await fs.readFile(new URL("./patches/app_generator.rb", import.meta.url).pathname, 'utf8');

    vm.eval(`
      Dir.chdir("${workdir}") unless "${workdir}".empty?

      ENV["RACK_HANDLER"] = "wasi"

      require "/rails-vm/boot"

      require "js"

      Wasmify::ExternalCommands.register(:server, :console)

      ${authenticationPatch}
      ${appGeneratorPatch}
    `)
  }

  return vm;
}
