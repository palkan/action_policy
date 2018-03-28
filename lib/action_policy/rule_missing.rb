# frozen_string_literal: true

module ActionPolicy
  # Add fallback to `manage?` rule if rule is not defined.
  # When `method_missing` is invoked an alias is created
  # (thus we could avoid `method_missing` later)
  module RuleMissing
    def respond_to_missing?(meth, include_private = false)
      meth.to_s.ends_with?("?") ? true : super
    end

    def method_missing(meth, *_args, &block)
      return super unless meth.to_s.ends_with?("?")

      self.class.class_eval do
        alias_method meth, :manage?
      end

      manage?
    end
  end
end
