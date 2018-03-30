# frozen_string_literal: true

require "test_helper"
require_relative "controllers_helper"

class TestViewsIntegration < ActionController::TestCase
  class UsersController < ActionController::Base
    self.view_paths = File.expand_path("./views/users", __dir__)

    authorize :current_user, as: :user

    def index
      @users = [
        User.new("guest"),
        User.new("admin")
      ]

      render template: "index"
    end

    def current_user
      @current_user ||= User.new(params[:user])
    end
  end

  tests UsersController

  def test_index_as_admin
    get :index, params: { user: "admin" }

    assert_includes response.body, "guest (editable)"
    assert_includes response.body, "admin (read-only)"
    assert_includes response.body, "Create User"
  end

  def test_index_as_guest
    get :index, params: { user: "guest" }

    assert_includes response.body, "guest (read-only)"
    assert_includes response.body, "admin (read-only)"
    refute_includes response.body, "Create User"
  end
end
