# frozen_string_literal: true

require "test_helper"

require "action_policy/ext/symbol_classify"
using ActionPolicy::Ext::SymbolClassify

class TestSymbolClassify < Minitest::Test
  def test_simple_name
    assert_equal "Test", :test.classify
  end

  def test_underscored_name
    assert_equal "TeStO", :te_st_o.classify
  end
end
