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
  %w[
    rails
    wasmify-rails
    propshaft
    importmap-rails
    turbo-rails
    stimulus-rails
    jbuilder
    bcrypt
    solid_cache
    solid_queue
    solid_cable
    image_processing
    tzinfo/data
  ].each do |gem_name|
    Kernel.require gem_name
  end
end
