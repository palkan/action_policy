# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Add `camelize` to Symbol
    module SymbolCamelize
      refine Symbol do
        if "".respond_to?(:camelize)
          def camelize
            to_s.camelize
          end
        else
          def camelize
            word = to_s.capitalize
            word.gsub!(/(?:_)([a-z\d]*)/) { $1.capitalize }
            word
          end
        end
      end
    end
  end
end
