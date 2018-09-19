# frozen_string_literal: true

module ActionPolicy
  module ScopeMatchers
    # Adds `relation_scope` method as an alias
    # for `scope_for :active_record_relation`
    module ActiveRecord
      def relation_scope(*args, &block)
        scope_for :active_record_relation, *args, &block
      end
    end
  end
end

# Register relation scope matcher
ActionPolicy::Base.scope_matcher :active_record_relation, ActiveRecord::Relation

# Add alias to base policy
ActionPolicy::Base.extend ActionPolicy::ScopeMatchers::ActiveRecord

ActiveRecord::Relation.include(Module.new do
  def policy_name
    if model.respond_to?(:policy_name)
      model.policy_name.to_s
    else
      "#{model}Policy"
    end
  end
end)
