# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Add simple safe_constantize method to String
    module StringConstantize
      refine String do
        def safe_constantize
          names = split("::")

          return nil if names.empty?

          # Remove the first blank element in case of '::ClassName' notation.
          names.shift if names.size > 1 && names.first.empty?

          begin
            names.inject(Object) do |constant, name|
              constant.const_get(name)
            end
          # rescue instead of const_defined? allow us to use
          # Rails const autoloading (aka patched const_get)
          rescue NameError
            nil
          end
        end
      end
    end
  end
end
