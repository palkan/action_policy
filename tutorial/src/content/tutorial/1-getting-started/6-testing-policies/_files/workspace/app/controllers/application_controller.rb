class ApplicationController < ActionController::Base
  include Authentication

  authorize :user, through: -> { Current.user }

  rescue_from ActionPolicy::Unauthorized do
    redirect_back fallback_location: unauthorized_redirect_path, alert: "Not authorized"
  end

  private

  def unauthorized_redirect_path = root_path
end
