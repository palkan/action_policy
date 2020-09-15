# frozen_string_literal: true

# This benchmark measures the difference between catch/throw and jump-less implementation.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "action_policy"
require "benchmark/ips"

GC.disable

class A; end

class B; end

class APolicy < ActionPolicy::Base
  authorize :user, optional: true

  def apply(rule)
    @result = self.class.result_class.new(self.class, rule)
    @result.load __apply__(rule)
  end

  def show?
    true
  end
end

class BPolicy < ActionPolicy::Base
  authorize :user, optional: true

  def apply(rule)
    @result = self.class.result_class.new(self.class, rule)

    catch :throw_me_away do
      @result.load __apply__(rule)
    end

    @result.value
  end

  def show?
    @result.load true

    throw :throw_me_away
  end
end

a = A.new

(APolicy.new(record: a).apply(:show?) == BPolicy.new(record: a).apply(:show?)) || raise("Implementations are not equal")

Benchmark.ips do |x|
  x.warmup = 0

  x.report("no catch/throw") do
    APolicy.new(record: a).apply(:show?)
  end

  x.report("with catch/throw") do
    BPolicy.new(record: a).apply(:show?)
  end

  x.compare!
end
