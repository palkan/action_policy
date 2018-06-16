# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Add yield_self and then if missing
    module YieldSelfThen
      refine BasicObject do
        unless nil.respond_to?(:yield_self)
          def yield_self
            yield self
          end
        end

        alias_method :then, :yield_self
      end
    end
  end
end
