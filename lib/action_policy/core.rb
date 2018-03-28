# frozen_string_literal: true

module ActionPolicy
  # Core policy API
  module Core
    attr_reader :object

    # Sets authorization object
    def set(object)
      @object = object
      self
    end

    # Returns a result of applying the specified rule.
    # Unlike simply calling a predicate rule (`policy.manage?`),
    # `apply` also calls pre-checks.
    def apply(rule)
      public_send(rule)
    end
  end
end
