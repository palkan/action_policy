# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Add transform_keys to Hash for older Rubys
    module HashTransformKeys
      refine Hash do
        def transform_keys
          return enum_for(:transform_keys) { size } unless block_given?
          result = {}
          each_key do |key|
            result[yield(key)] = self[key]
          end
          result
        end
      end
    end
  end
end
