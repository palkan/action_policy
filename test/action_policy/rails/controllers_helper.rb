# frozen_string_literal: true

require "action_controller"
require "action_policy/rails/controller"

ActionController::Base.include(ActionPolicy::Controller)

SharedTestRoutes = ActionDispatch::Routing::RouteSet.new

SharedTestRoutes.draw do
  ActiveSupport::Deprecation.silence do
    get ":controller(/:action)"
  end
end

ActionController::TestCase.include(
  Module.new do
    def before_setup
      @routes = SharedTestRoutes
      super
    end
  end
)
