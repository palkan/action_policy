# frozen_string_literal: true

require "test_helper"

class TestApplyCache < Minitest::Test
  class TestPolicy
    include ActionPolicy::Core
    include ActionPolicy::ApplyCache

    attr_reader :managed_count

    def manage?
      @managed_count ||= 0
      @managed_count += 1

      record
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
end
