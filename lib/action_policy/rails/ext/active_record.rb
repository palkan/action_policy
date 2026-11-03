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
    return object_id.to_s unless persisted?
    # A select leaving updated_at out makes cache_version raise MissingAttributeError
    return object_id.to_s if !has_attribute?("updated_at") && self.class.attribute_types.key?("updated_at")

    cache_key_with_version
  end
end)
