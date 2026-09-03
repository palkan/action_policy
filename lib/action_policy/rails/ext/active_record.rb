# frozen_string_literal: true

# Add explicit #policy_cache_key to Relation to
# avoid calling #cache_key.
# See https://github.com/palkan/action_policy/issues/55
ActiveRecord::Relation.include(Module.new do
  def policy_cache_key
    object_id
  end

  # Explicitly define the policy_class method to avoid
  # making Relation immutable (by initializing `arel` in `#respond_to_missing?).
  # See https://github.com/palkan/action_policy/issues/101
  def policy_class
    nil
  end
end)

# Ensure non-persistent models are not cached as a single entry
ActiveRecord::Base.include(Module.new do
  def policy_cache_key
    if persisted?
      cache_key_with_version
    else
      object_id.to_s
    end
  end
end)
