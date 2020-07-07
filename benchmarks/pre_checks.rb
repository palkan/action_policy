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

  pre_check :do_nothing, :deny_all

  def show?
    true
  end

  def do_nothing
  end

  def deny_all
    deny!
  end
end

class BPolicy < APolicy
  def run_pre_checks(rule)
    catch :policy_fulfilled do
      self.class.pre_checks.each do |check|
        next unless check.applicable?(rule)
        check.call(self)
      end

      return yield if block_given?
    end

    result.value
  end

  def deny!
    result.load false
    throw :policy_fulfilled
  end
end

a = A.new

(APolicy.new(record: a).apply(:show?) == BPolicy.new(record: a).apply(:show?)) || raise("Implementations are not equal")

Benchmark.ips do |x|
  x.warmup = 0

  x.report("loop pre-check") do
    APolicy.new(record: a).apply(:show?)
  end

  x.report("catch/throw pre-check") do
    BPolicy.new(record: a).apply(:show?)
  end

  x.compare!
end

# Comparison:
# catch/throw pre-check:   286094.2 i/s
#      loop pre-check:   184786.1 i/s - 1.55x  slower
