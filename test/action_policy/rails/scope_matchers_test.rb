# frozen_string_literal: true

require "test_helper"
require_relative "controllers_helper"
require_relative "active_record_helper"

require_relative "dummy/config/environment"

if ActionPack.version.release < Gem::Version.new("5")
  require_relative "controller_rails_4"
  using ControllerRails4
end

class TestRailsScopeMatchers < ActionController::TestCase
  class UserPolicy < ActionPolicy::Base
    authorize :user

    relation_scope do |scope|
      (user.role == "guest") ? scope.where(role: "guest") : scope.all
    end

    params_filter do |params|
      if user.role == "admin"
        params.permit(:name, :role)
      else
        params.permit(:name)
      end
    end

    params_filter(:update) do |params|
      params.permit(:name)
    end
  end

  class PostPolicy < ActionPolicy::Base
    relation_scope do |scope|
      if user.role == "admin"
        scope.all
      else
        scope.where(draft: false)
      end
    end
  end

  class UsersController < ActionController::Base
    authorize :user, through: :current_user

    def index
      render json: authorized_scope(AR::User.all)
    end

    def posts
      render json: authorized_scope(current_user.posts)
    end

    def create
      user = AR::User.create!(authorized(params.require(:user)))
      render json: user
    end

    def update
      current_user.update!(authorized(params.require(:user), as: :update))
      render json: current_user
    end

    private

    def current_user
      @current_user ||= AR::User.find(params[:user_id])
    end

    # Make sure that we do not fallback to implicit target
    # when testing relations
    def implicit_authorization_target
      return nil if request.get?
      super
    end
  end

  tests UsersController

  attr_reader :admin, :guest

  def setup
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    @guest = AR::User.create!(name: "Jack")
    @admin = AR::User.create!(name: "John", role: "admin")
  end

  def teardown
    ActiveRecord::Base.connection.rollback_transaction
  end

  def json_body
    @json_body ||= JSON.parse(response.body)
  end

  def test_authorized_relation_guest
    get :index, params: {user_id: guest.id}

    assert_equal 1, json_body.size
    assert_equal "Jack", json_body.first["name"]
  end

  def test_authorized_relation_admin
    get :index, params: {user_id: admin.id}

    assert_equal 2, json_body.size
  end

  def test_authorized_association
    AR::Post.create!(draft: true, title: "[wip]", user: guest)
    AR::Post.create!(draft: false, title: "Good news!", user: guest)

    get :posts, params: {user_id: guest.id}

    assert_equal 1, json_body.size
    assert_equal "Good news!", json_body.first["title"]
  end

  def test_authorized_association_2
    AR::Post.create!(draft: false, title: "[wip]", user: guest)
    AR::Post.create!(draft: false, title: "Admin news", user: admin)
    AR::Post.create!(draft: false, title: "Good news!", user: guest)

    get :posts, params: {user_id: guest.id}

    assert_equal 2, json_body.size
  end

  def test_filtered_params_guest
    post :create, params: {user_id: guest.id, user: {name: "Alice", role: "admin"}}

    alice = AR::User.find_by!(name: "Alice")

    assert_equal "guest", alice.role
  end

  def test_filtered_params_admin
    post :create, params: {user_id: admin.id, user: {name: "Alice", role: "admin"}}

    alice = AR::User.find_by!(name: "Alice")

    assert_equal "admin", alice.role
  end

  def test_named_filtered_params_admin
    patch :update, params: {user_id: admin.id, user: {name: "Deadmin", role: "guest"}}

    admin.reload

    assert_equal "Deadmin", admin.name
    assert_equal "admin", admin.role
  end
end

# See https://github.com/palkan/action_policy/issues/101
class TestRelationMutability < ActionController::TestCase
  class UserPolicy < ActionPolicy::Base
    authorize :user

    relation_scope { |scope| scope }
  end

  class UsersController < ActionController::Base
    authorize :user, through: :current_user

    def index
      users = authorized_scope(AR::User.all)
      users.order!(name: :asc)
      render json: users
    end

    private

    def current_user
      @current_user ||= AR::User.find(params[:user_id])
    end
  end

  tests UsersController

  attr_reader :admin, :guest

  def setup
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    @guest = AR::User.create!(name: "Jack")
    @admin = AR::User.create!(name: "John", role: "admin")
  end

  def teardown
    ActiveRecord::Base.connection.rollback_transaction
  end

  def json_body
    @json_body ||= JSON.parse(response.body)
  end

  def test_do_not_raise_immutable_relation
    get :index, params: {user_id: admin.id}

    assert_equal 2, json_body.size
    assert_equal "John", json_body.last["name"]
  end
end

class TestRailsScopeMatchersWithoutImplicitTarget < ActionController::TestCase
  class UserPolicy < ActionPolicy::Base
    authorize :user

    params_filter(:update) do |params|
      params.permit(:name)
    end
  end

  class CurrentUsersController < ActionController::Base
    authorize :user, through: :current_user

    def update
      current_user.update!(authorized(params.require(:current_user), with: UserPolicy, as: :update))
      render json: current_user
    end

    private

    def current_user
      @current_user ||= AR::User.find(params[:user_id])
    end
  end

  tests CurrentUsersController

  attr_reader :admin, :guest

  def setup
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    @guest = AR::User.create!(name: "Jack")
    @admin = AR::User.create!(name: "John", role: "admin")
  end

  def teardown
    ActiveRecord::Base.connection.rollback_transaction
  end

  def test_params_filtering_with_no_implicit_target
    patch :update, params: {user_id: admin.id, current_user: {name: "Deadmin", role: "guest"}}

    admin.reload

    assert_equal "Deadmin", admin.name
    assert_equal "admin", admin.role
  end
end
