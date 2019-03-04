# frozen_string_literal: true

require "action_controller"
require "action_policy/rails/controller"

ActionController::Base.include(ActionPolicy::Controller)

ActionController::Base.include(Module.new do
  def _routes
  end
end)

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

    def teardown
      ActionPolicy::PerThreadCache.clear_all
    end
  end
)
