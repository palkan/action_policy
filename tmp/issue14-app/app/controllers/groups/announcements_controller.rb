class Groups::AnnouncementsController < ApplicationController
  def show
    authorize!

    head :ok
  end

  def current_user; end
end
