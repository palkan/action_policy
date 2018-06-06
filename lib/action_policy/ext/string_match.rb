# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Add match? to String for older Rubys
    module StringMatch
      refine String do
        def match?(regexp)
          !regexp.match(self).nil?
        end
      end
    end
  end
end
