# frozen_string_literal: true

module ActionPolicy
  module Policy
    # Create default rules and aliases:
    # - `index?` (=`false`)
    # - `create?` (=`false`)
    # - `new?` as an alias for `create?`
    # - `manage?` as a fallback for all unspecified rules (default rule)
    module Defaults
      def self.included(base)
        raise "Aliases support is required for defaults" unless
          base.ancestors.include?(Aliases)

        base.default_rule :manage?
        base.alias_rule :new?, to: :create?

        raise "Verification context support is required for defaults" unless
          base.ancestors.include?(Aliases)

        base.authorize :user
      end

      def index?() = false

      def create?() = false

      def manage?() = false
    end
  end
end
