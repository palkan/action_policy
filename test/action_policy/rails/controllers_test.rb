# frozen_string_literal: true

require "test_helper"
require_relative "controllers_helper"

class TestSimpleControllerIntegration < ActionController::TestCase
  class UsersController < ActionController::Base
    authorize :current_user, as: :user

    before_action :set_user, only: [:update, :show]

    def index
      authorize!
      render plain: "OK"
    end

    def create
      authorize!
      render plain: "OK"
    end

    def update
      render plain: "OK"
    end

    def show
      if allowed_to?(:update?, @user)
        render plain: "OK"
      else
        render plain: "Read-only"
      end
    end

    def current_user
      @current_user ||= User.new(params[:user])
    end

    private

    def set_user
      @user = User.new(params[:target])
      authorize! @user
    end
  end

  tests UsersController

  def test_index
    get :index
    assert_equal "OK", response.body
  end

  def test_create_failed
    e = assert_raises(ActionPolicy::Unauthorized) do
      post :create, params: { user: "guest" }
    end

    assert_equal UserPolicy, e.policy
    assert_equal "create?", e.rule
    assert e.reasons.is_a?(::ActionPolicy::FailureReasons)
  end

  def test_create_succeed
    post :create, params: { user: "admin" }
    assert_equal "OK", response.body
  end

  def test_update_failed
    assert_raises(ActionPolicy::Unauthorized) do
      patch :update, params: { user: "admin", target: "admin" }
    end
  end

  def test_update_succeed
    patch :update, params: { user: "admin", target: "guest" }
    assert_equal "OK", response.body
  end

  def test_show
    get :show, params: { user: "admin", target: "guest" }
    assert_equal "OK", response.body
  end

  def test_show_admin
    get :show, params: { user: "admin", target: "admin" }
    assert_equal "Read-only", response.body
  end
end
