# frozen_string_literal: true

require "test_helper"

require "action_policy/ext/policy_cache_key"
using ActionPolicy::Ext::PolicyCacheKey

class TestPolicyCacheKey < Minitest::Test
  class Base; end

  class CachedKey < Base
    def cache_key
      "cache"
    end
  end

  class PolicyCached < CachedKey
    def policy_cache_key
      "pcache"
    end
  end

  def test_core_classes
    assert_equal "1", 1._policy_cache_key
    assert_equal "3.14", 3.14._policy_cache_key
    assert_equal "t", true._policy_cache_key
    assert_equal "", nil._policy_cache_key
    assert_equal "abc", "abc"._policy_cache_key
    assert_equal "xyz", :xyz._policy_cache_key
  end

  def test_object_id_fallback
    obj = Base.new

    assert_equal obj.object_id.to_s, obj._policy_cache_key(use_object_id: true)
  end

  def test_raise_without_fallback
    assert_raises ArgumentError do
      Base.new._policy_cache_key
    end
  end

  def test_cache_key
    obj = CachedKey.new

    assert_equal "cache", obj._policy_cache_key
  end

  def test_policy_cache_key
    obj = PolicyCached.new

    assert_equal "pcache", obj._policy_cache_key
  end
end
