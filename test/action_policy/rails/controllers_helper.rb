# frozen_string_literal: true

require "action_controller"
require "action_policy/rails/controller"

ActionController::Base.include(ActionPolicy::Controller)

ActionController::Base.include(Module.new do
  def _routes
  end
end)

ActionController::TestCase.include(
  Module.new do
    def before_setup
      controller = self.class.controller_class

      @routes = ActionDispatch::Routing::RouteSet.new.tap do |routes|
        routes.draw do
          next unless controller&.name

          path = controller.controller_path

          controller.action_methods.each do |action|
            match "#{path}/#{action}", to: "#{path}##{action}", via: :all
          end
        end
      end
      super
    end

    def teardown
      ActionPolicy::PerThreadCache.clear_all
    end
  end
)
