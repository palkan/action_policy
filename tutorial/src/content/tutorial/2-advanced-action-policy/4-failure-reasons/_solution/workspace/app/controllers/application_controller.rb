class ApplicationController < ActionController::Base
  include Authentication

  authorize :user, through: -> { Current.user }

  rescue_from ActionPolicy::Unauthorized do |ex|
    redirect_back fallback_location: unauthorized_redirect_path,
      alert: ex.result.reasons.full_messages.to_sentence.presence || ex.result.message
  end

  private

  def unauthorized_redirect_path = root_path
end
