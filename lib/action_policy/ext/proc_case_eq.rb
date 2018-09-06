# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Add #=== to Proc
    module ProcCaseEq
      refine Proc do
        def ===(other)
          call(other) == true
        end
      end
    end
  end
end
