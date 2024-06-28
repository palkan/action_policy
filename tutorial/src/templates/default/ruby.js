import { RubyVM } from "@ruby/wasm-wasi";
import rubyUrl from "./node_modules/@ruby/3.3-wasm-wasi/dist/ruby+stdlib.wasm?url";
import { File, WASI, OpenFile, ConsoleStdout } from "@bjorn3/browser_wasi_shim";

export default async function initVM(setStdout, setStderr) {
  console.log("Initializing ruby.wasm...");
  const fds = [
    new OpenFile(new File([])), // stdin
    ConsoleStdout.lineBuffered(setStdout),
    ConsoleStdout.lineBuffered(setStderr),
  ];
  const wasi = new WASI([], [], fds, { debug: false });
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);

  const wasmModulePromise = fetch(rubyUrl).then((response) =>
    WebAssembly.compileStreaming(response)
  );
  const instance = await WebAssembly.instantiate(
    await wasmModulePromise,
    imports
  );
  await vm.setInstance(instance);

  wasi.initialize(instance);
  vm.initialize(["ruby.wasm", "-e_=0", "-EUTF-8"]);
  console.log("ruby.wasm initialized");

  return vm;
}
