# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Add Module#namespace method
    module ModuleNamespace
      refine Module do
        unless "".respond_to?(:safe_constantize)
          require "action_policy/ext/string_constantize"
          using ActionPolicy::Ext::StringConstantize
        end

        unless "".respond_to?(:match?)
          require "action_policy/ext/string_match"
          using ActionPolicy::Ext::StringMatch
        end

        def namespace
          return unless name.match?(/[^^]::/)

          name.sub(/::[^:]+$/, "").safe_constantize
        end
      end
    end
  end
end
