# frozen_string_literal: true

require "test_helper"

class TestCachedApply < Minitest::Test
  class TestPolicy
    include ActionPolicy::Policy::Core
    include ActionPolicy::Policy::Reasons
    include ActionPolicy::Policy::CachedApply

    self.identifier = :test

    attr_reader :managed_count

    def manage?
      @managed_count ||= 0
      @managed_count += 1

      record
    end

    def kill?
      allowed_to?(:manage?)
    end
  end

  def test_cache_truth
    policy = TestPolicy.new true

    assert policy.apply(:manage?)
    assert policy.apply(:manage?)

    assert_equal 1, policy.managed_count
  end

  def test_cache_falsey
    policy = TestPolicy.new false

    refute policy.apply(:manage?)
    refute policy.apply(:manage?)

    assert_equal 1, policy.managed_count
  end

  def test_cache_with_reasons
    policy = TestPolicy.new false

    refute policy.apply(:kill?)
    assert_equal({test: [:manage?]}, policy.result.reasons.details)

    refute policy.apply(:kill?)
    assert_equal({test: [:manage?]}, policy.result.reasons.details)

    assert_equal 1, policy.managed_count
  end
end
