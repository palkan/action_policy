# frozen_string_literal: true

=begin

This benchmark measures the efficiency of NamespaceCache.

Run it multiple times with cache on/off to see the results:

  $ bundle exec ruby namespaced_lookup_cache.rb
  $ bundle exec ruby namespaced_lookup_cache.rb
  $ NO_CACHE=1 bundle exec ruby namespaced_lookup_cache.rb
  $ NO_CACHE=1 bundle exec ruby namespaced_lookup_cache.rb

=end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "action_policy"
require "benchmark/ips"

GC.disable

class A; end

class B; end

module X
  class BPolicy < ActionPolicy::Base; end

  module Y
    module Z
      class APolicy < ActionPolicy::Base; end
    end
  end
end

a = A.new
b = B.new

if ENV['NO_CACHE']
  ActionPolicy::LookupChain.namespace_cache_enabled = false
end

Benchmark.ips do |x|
  x.warmup = 0

  x.report("cache A") do
    ActionPolicy.lookup(a, namespace: X::Y::Z)
  end

  x.report("cache B") do
    ActionPolicy.lookup(b, namespace: X::Y::Z)
  end

  x.report("no cache A") do
    ActionPolicy.lookup(a, namespace: X::Y::Z)
  end

  x.report("no cache B") do
    ActionPolicy.lookup(b, namespace: X::Y::Z)
  end

  x.hold! 'temp_results'

  x.compare!
end

=begin

Comparison:
            cache B:   178577.4 i/s
            cache A:   173061.4 i/s - same-ish: difference falls within error
        no cache A:    97991.7 i/s - same-ish: difference falls within error
        no cache B:    42505.4 i/s - 4.20x  slower
=end
