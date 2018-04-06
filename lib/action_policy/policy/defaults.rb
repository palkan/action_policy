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
        # Aliases module is required for defaults
        base.prepend Aliases unless base.ancestors.include?(Aliases)

        base.default_rule :manage?
        base.alias_rule :new?, to: :create?
      end

      def index?
        false
      end

      def create?
        false
      end

      def manage?
        false
      end
    end
  end
end
