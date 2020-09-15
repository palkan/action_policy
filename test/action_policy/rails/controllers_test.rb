# frozen_string_literal: true

require "test_helper"
require_relative "controllers_helper"

if ActionPack.version.release < Gem::Version.new("5")
  require_relative "controller_rails_4"
  using ControllerRails4
end

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
    get :index, params: {user: "guest"}
    assert_equal "OK", response.body
  end

  def test_create_failed
    e = assert_raises(ActionPolicy::Unauthorized) do
      post :create, params: {user: "guest"}
    end

    assert_equal UserPolicy, e.policy
    assert_equal :create?, e.rule
    assert e.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
  end

  def test_create_succeed
    post :create, params: {user: "admin"}
    assert_equal "OK", response.body
  end

  def test_update_failed
    assert_raises(ActionPolicy::Unauthorized) do
      patch :update, params: {user: "admin", target: "admin"}
    end
  end

  def test_update_succeed
    patch :update, params: {user: "admin", target: "guest"}
    assert_equal "OK", response.body
  end

  def test_show
    get :show, params: {user: "admin", target: "guest"}
    assert_equal "OK", response.body
  end

  def test_show_admin
    get :show, params: {user: "admin", target: "admin"}
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
      skip_verify_authorized! if params[:skip_authorization]
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

  def test_skip_verify_authorized_dynamically
    get :create, params: {skip_authorization: "Y"}
    assert_equal "OK", response.body
  end

  def test_skipped_verify_show
    get :show
    assert_equal "OK", response.body
  end
end

class TestNamespacedControllerIntegration < ActionController::TestCase
  module Admin
    class UserPolicy < ::UserPolicy
      authorize :user, allow_nil: true

      def index?
        user.present?
      end

      def show?
        user&.admin?
      end
    end

    class UsersController < ActionController::Base
      authorize :user, through: :current_user

      def index
        authorize!
        render plain: "OK"
      end

      def show
        authorize! current_user
        render plain: "OK"
      end

      def current_user
        return unless params[:user]
        @current_user ||= User.new(params[:user])
      end
    end
  end

  tests Admin::UsersController

  def test_index_unauthorized
    e = assert_raises(ActionPolicy::Unauthorized) do
      get :index
    end

    assert_equal Admin::UserPolicy, e.policy
    assert_equal :index?, e.rule
  end

  def test_index_authorized
    get :index, params: {user: "guest"}
    assert_equal "OK", response.body
  end

  def test_show_unauthorized
    e = assert_raises(ActionPolicy::Unauthorized) do
      get :show, params: {user: "guest"}
    end

    assert_equal Admin::UserPolicy, e.policy
    assert_equal :show?, e.rule
  end

  def test_show_authorized
    get :show, params: {user: "admin"}
    assert_equal "OK", response.body
  end
end
