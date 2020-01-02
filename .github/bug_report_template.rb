# frozen_string_literal: true

require "bundler/inline"

# This reproduction script allows you to test Action Policy with Rails.
# It contains:
#   - Headless User model
#   - UserPolicy
#   - UsersController
#   - Example tests for the controller.
#
# Update the classes to reproduce the failing case.
#
# Run the script as follows:
#
#   $ ruby bug_report_template.rb
gemfile(true) do
  source "https://rubygems.org"

  gem "rails", "~> 6.0"
  gem "action_policy", "~> 0.4"

  gem "pry-byebug", platform: :mri
end

require "rails"
require "action_controller/railtie"
require "action_policy"

require "minitest/autorun"

module Buggy
  class Application < Rails::Application
    config.logger = Logger.new("/dev/null")
    config.eager_load = false

    initializer "routes" do
      Rails.application.routes.draw do
        get ":controller(/:action)"
      end
    end
  end
end

Rails.application.initialize!

class User
  include Comparable

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def admin?
    name == "admin"
  end

  def <=>(other)
    return super unless other.is_a?(User)
    name <=> other.name
  end
end

class UserPolicy < ActionPolicy::Base
  def index?
    true
  end

  def create?
    user.admin?
  end

  def show?
    true
  end

  def manage?
    user.admin? && !record.admin?
  end
end

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

class TestBugReproduction < ActionController::TestCase
  tests UsersController

  def before_setup
    @routes = Rails.application.routes
    super
  end

  def teardown
    ActionPolicy::PerThreadCache.clear_all
  end

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
