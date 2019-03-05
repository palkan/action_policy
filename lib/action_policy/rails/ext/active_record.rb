# frozen_string_literal: true

# Add explicit #policy_cache_key to Relation to
# avoid calling #cache_key.
# See https://github.com/palkan/action_policy/issues/55
ActiveRecord::Relation.include(Module.new do
  def policy_cache_key
    object_id
  end
end)
