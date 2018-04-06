# frozen_string_literal: true

module ActionPolicy # :nodoc:
  class << self
    # Define whether we need to extend ApplicationController::Base
    # with the default authorization logic.
    attr_accessor :auto_inject_into_controller
  end

  self.auto_inject_into_controller = true

  class Railtie < ::Rails::Railtie # :nodoc:
    config.after_initialize do |_app|
      ActiveSupport.on_load(:action_controller) do
        next unless ActionPolicy.auto_inject_into_controller

        require "action_policy/rails/controller"

        ActionController::Base.include ActionPolicy::Controller
      end
    end
  end
end
