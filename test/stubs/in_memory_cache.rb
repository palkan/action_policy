# frozen_string_literal: true

class InMemoryCache
  attr_accessor :store

  def initialize
    self.store = {}
  end

  def read(key)
    deserialize(store[key]) if store.key?(key)
  end

  def write(key, val, _options)
    store[key] = serialize(val)
  end

  def serialize(val)
    Marshal.dump(val)
  end

  def deserialize(val)
    Marshal.load(val)
  end
end
