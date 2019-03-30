# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Add `classify` to Symbol
    module SymbolClassify
      refine Symbol do
        if "".respond_to?(:classify)
          def classify
            to_s.classify
          end
        else
          def classify
            word = to_s.capitalize
            word.gsub!(/(?:_)([a-z\d]*)/) { $1.capitalize }
            word
          end
        end
      end
    end
  end
end
