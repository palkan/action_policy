import "./style.css";
import initVM from "./ruby.js";

import exampleFile from "./wordcount.rb?raw";
import testFile from "./wordcount_test.rb?raw";

const terminalEl = document.querySelector("#app");

function printLine(...lines) {
  for (const line of lines) {
    const p = document.createElement("p");
    p.textContent = line;
    terminalEl.appendChild(p);
  }
}

function printError(msg) {
  const p = document.createElement("p");
  p.textContent = msg;
  p.classList.add("error");
  terminalEl.appendChild(p);
}

printLine("Initializing ruby.wasm...");
const vm = await initVM(
  function (line) {
    printLine(line);
    console.log(line);
  },
  function (line) {
    printLine(line);
    console.warn(line);
  }
);

printLine(`ruby.wasm initialized: ${vm.eval("RUBY_DESCRIPTION").toString()}`);
printLine("");

try {
  vm.eval(exampleFile);
  printLine(" ", "Running wordcount_test.rb:", " ");
  vm.eval(testFile);
} catch (e) {
  printError(e.toString());
}
