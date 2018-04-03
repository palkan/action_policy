# frozen_string_literal: true

module ActionPolicy
  class Railtie < ::Rails::Railtie # :nodoc:
    initializer "action_policy.controller" do |_app|
      ActiveSupport.on_load(:action_controller) do
        require "action_policy/rails/controller"

        ActionController::Base.include ActionPolicy::Controller
      end
    end
  end
end
