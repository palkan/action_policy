# frozen_string_literal: true

module ControllerRails4
  refine ActionController::Base do
    def params
      super[:params] || {}
    end
  end
end
