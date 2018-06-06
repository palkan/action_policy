# frozen_string_literal: true

require "test_helper"
require_relative "controllers_helper"

class TestSimpleControllerIntegration < ActionController::TestCase
  class UsersController < ActionController::Base
    authorize :user, through: :current_user

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
      @current_user ||= User.new(params[:user] || params[:params][:user])
    end

    private

    def set_user
      @user = User.new(params[:target] || params[:params][:target])
      authorize! @user
    end
  end

  tests UsersController

  def test_index
    get :index, params: { user: "guest" }
    assert_equal "OK", response.body
  end

  def test_create_failed
    e = assert_raises(ActionPolicy::Unauthorized) do
      post :create, params: { user: "guest" }
    end

    assert_equal UserPolicy, e.policy
    assert_equal :create?, e.rule
    assert e.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
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

class TestControllerHookIntegration < ActionController::TestCase
  class UsersController < ActionController::Base
    authorize :user, through: :current_user

    verify_authorized except: [:index]

    skip_verify_authorized only: [:show]

    def index
      render plain: "OK"
    end

    def new
      authorize!
      render plain: "OK"
    end

    def create
      render plain: "OK"
    end

    def show
      render plain: "OK"
    end

    def current_user
      @current_user ||= User.new("admin")
    end
  end

  tests UsersController

  def test_non_verified_index
    get :index
    assert_equal "OK", response.body
  end

  def test_verified_new
    get :new
    assert_equal "OK", response.body
  end

  def test_missing_authorize_create
    assert_raises(ActionPolicy::UnauthorizedAction) do
      get :create
    end
  end

  def test_skipped_verify_show
    get :show
    assert_equal "OK", response.body
  end
end
