# frozen_string_literal: true

require "test_helper"

require "action_policy/ext/string_underscore"
using ActionPolicy::Ext::StringUnderscore

class TestStringUnderscore < Minitest::Test
  def test_simple_class_name
    assert_equal "test", "Test".underscore
  end

  def test_camelcased_word
    assert_equal "te_st_o", "TeStO".underscore
  end

  def test_namespaced_class_name
    assert_equal "my/suppa_duppa/te_st", "My::SuppaDuppa::TeSt".underscore
  end
end
