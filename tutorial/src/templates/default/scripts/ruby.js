import fs from "fs/promises";
import { DefaultRubyVM } from "@ruby/wasm-wasi/dist/node";

const main = async () => {
  const binary = await fs.readFile(
    "./node_modules/@ruby/3.3-wasm-wasi/dist/ruby.wasm"
  );
  const module = await WebAssembly.compile(binary);
  const { vm } = await DefaultRubyVM(module);

  vm.printVersion();
};

main();
