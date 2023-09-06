# frozen_string_literal: true

module ActionPolicy
  module Ext
    # Add underscore to String
    module StringUnderscore
      refine String do
        def underscore
          word = gsub("::", "/")
          word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
          word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
          word.downcase!
          word
        end
      end
    end
  end
end
