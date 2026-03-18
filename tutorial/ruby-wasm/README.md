To create a `ruby.wasm` module, run the following commands:

```sh
bundle install
bin/pack
```


## Prerequisites

To build and pack Ruby Wasm modules, you need the following:

- Rust toolchain:

  ```sh
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

- [wasi-vfs](https://github.com/kateinoigakukun/wasi-vfs)
