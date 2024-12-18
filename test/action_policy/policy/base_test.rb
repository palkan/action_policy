# frozen_string_literal: true

require "test_helper"

class TestBasePolicy < Minitest::Test
  class User < Struct.new(:kind)
  end

  class FiberUser < User
    def kind
      Fiber.yield
      super
    end
  end

  class TestPolicy < ActionPolicy::Base
    self.identifier = :test

    authorize :user

    def milk?
      check?(:cat?)
    end

    def honey?
      check?(:bee?)
    end

    def cat? = user.kind == "cat"

    def bee? = user.kind == "bee"
  end

  def test_baseline
    user = User.new("cat")
    policy = TestPolicy.new(user: user)

    assert policy.apply(:milk?)
    refute policy.apply(:honey?)
    assert_equal({test: [:bee?]}, policy.result.reasons.details)

    # it's cached
    user.kind = "bee"

    assert policy.apply(:milk?)
    refute policy.apply(:honey?)
  end

  def test_fiber_concurrency
    user = FiberUser.new("cat")
    policy = TestPolicy.new(user: user)

    f1 = Fiber.new do
      refute policy.apply(:honey?)
      assert_equal({test: [:bee?]}, policy.result.reasons.details)
    end

    f2 = Fiber.new do
      assert policy.apply(:milk?)
    end

    f1.resume
    f2.resume
    f2.resume
    f1.resume
  end
end
