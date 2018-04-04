# frozen_string_literal: true

module ActionPolicy
  module Policy
    # Contains rules for standard CRUD operations:
    # - `index?` (=`true`)
    # - `create?` (=`false`)
    # - `new?` as an alias for `create?`
    # - `manage?` as a fallback for all unspecified rules.
    module Defaults
      def index?
        true
      end

      def create?
        false
      end

      def new?
        create?
      end

      def manage?
        false
      end
    end
  end
end
