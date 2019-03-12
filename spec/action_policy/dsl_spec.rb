# frozen_string_literal: true

require "spec_helper"
require "action_policy/rspec/dsl"

class UserPolicy < ActionPolicy::Base
  scope_for :data do |users, with_admins: false|
    next users if user.admin? || with_admins
    users.reject(&:admin?)
  end

  scope_for :data, :own do |users|
    users.select { |u| u.name == user.name }
  end

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

describe UserPolicy, type: :policy do
  let(:user) { User.new("guest") }
  let(:admin) { User.new("admin") }
  let(:context) { {user: user} }

  describe_rule :manage? do
    let(:record) { User.new("guest") }

    failed

    succeed "when user is admin" do
      let(:user) { admin }

      failed "when target user is also admin", some: :tag do
        let(:record) { User.new("admin") }
      end
    end
  end
end
