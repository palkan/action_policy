# frozen_string_literal: true

module ActionPolicy
  module Ext # :nodoc: all
    # Add yield_self and then if missing
    module YieldSelfThen
      module Ext
        unless nil.respond_to?(:yield_self)
          def yield_self
            yield self
          end
        end

        alias then yield_self
      end

      # See https://github.com/jruby/jruby/issues/5220
      ::Object.include(Ext) if RUBY_PLATFORM =~ /java/i

      refine Object do
        include Ext
      end
    end
  end
end
