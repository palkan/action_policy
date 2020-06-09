# frozen_string_literal: true

# Skip this test if the lookup chain is already defined. This is the case when
# *not* running in isolated mode (`bundle exec rake test:isolated`).
return if defined?(ActionPolicy::LookupChain)

require_relative "./dummy/config/environment"
require "test_helper"

class EntityPolicy; end

class TestLookupChain < Minitest::Test
  def test_symbol_singular
    assert_equal(
      EntityPolicy,
      ActionPolicy.lookup(:entity)
    )
  end

  def test_symbol_plural
    assert_equal(
      EntityPolicy,
      ActionPolicy.lookup(:entities)
    )
  end
end
