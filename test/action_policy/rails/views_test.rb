# frozen_string_literal: true

require "test_helper"
require_relative "controllers_helper"

if ActionPack.version.release < Gem::Version.new("5")
  require_relative "controller_rails_4"
  using ControllerRails4
end

class TestViewsIntegration < ActionController::TestCase
  class UsersController < ActionController::Base
    self.view_paths = File.expand_path("./views/users", __dir__)

    authorize :user, through: :current_user

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

class TestControllerViewsMemoization < ActionController::TestCase
  class UserPolicy < ::UserPolicy
    class << self
      def policies
        @policies ||= []
      end

      def reset
        @policies = []
      end
    end

    def initialize(*)
      super
      self.class.policies << self
    end
  end

  class User < ::User
    def policy_class
      UserPolicy
    end

    def cache_key
      "user/#{name}"
    end
  end

  class UsersController < ActionController::Base
    self.view_paths = File.expand_path("./views/users", __dir__)

    authorize :user, through: :current_user

    def index
      @users = [
        User.new("guest"),
        User.new("guest")
      ]

      authorize! @users.first, to: :update?

      render template: "index"
    end

    def current_user
      @current_user ||= User.new(params[:user])
    end
  end

  tests UsersController

  def test_memoize_policies
    get :index, params: { user: "admin" }

    assert_includes response.body, "guest (editable)"
    assert_includes response.body, "guest (editable)"
    assert_includes response.body, "Create User"

    # One for admin user and one for class (`create?`)
    assert_equal 2, UserPolicy.policies.size
  end
end
