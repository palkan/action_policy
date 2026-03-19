# Put all the code required to initialize the Rails Wasm environment

# Common Rails shims
require "wasmify/rails/shim"

# Load Rails patches
require "wasmify/rails/patches"

# Setup external commands
require "wasmify/external_commands"

# Patch Bundler.require to only require precompiled deps
# (We don't want to deal with group: :wasm here)
def Bundler.require(*groups)
  gemfile = ENV["BUNDLE_GEMFILE"] || File.join(__dir__, "Gemfile")
  definition = Bundler::Dsl.evaluate(gemfile, nil, {})
  definition.dependencies.each do |dep|
    requires = Array(dep.autorequire || dep.name)
    requires.each do |req|
      Kernel.require req
    rescue LoadError
      Kernel.require req.tr("-", "/")
    end
  end
end
