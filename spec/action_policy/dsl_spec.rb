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

  # test skip rule
  xdescribe_rule :manage? do
    succeed
  end

  describe_rule :manage? do
    let(:record) { User.new("guest") }

    failed

    succeed "when user is admin" do
      let(:user) { admin }

      failed "when target user is also admin", some: :tag do
        let(:record) { User.new("admin") }
      end
    end

    context "test errors" do
      after do |ex|
        msg = ex.exception.message
        # mark as not failed
        ex.remove_instance_variable(:@exception)

        expect(msg).to include("<UserPolicy#manage?: true>")
        expect(msg).to include("↳ user.admin? #=> #{ActionPolicy::PrettyPrint.colorize(true)}") if ActionPolicy::PrettyPrint.available?
      end

      failed do
        let(:user) { admin }
      end
    end

    context "test skip" do
      xfailed do
        let(:user) { admin }
      end
    end
  end
end
