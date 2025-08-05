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

  def delete?
    user.admin? && check?(:not_admin?)
  end

  def not_admin?
    details[:username] = record.name
    !record.admin?
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

  describe_rule :delete? do
    let(:user) { admin }
    let(:record) { User.new("admin") }

    failed "when user is not an admin", reason: {user: [{not_admin?: {username: "admin"}}]}

    context "test errors with reasons" do
      after do |ex|
        msg = ex.exception.message
        # mark as not failed
        ex.remove_instance_variable(:@exception)

        expect(msg).to include(<<~MESSAGE.strip)
          Expected to fail with :unexpected but but actually failed for another reason:
          <UserPolicy#delete?: false (reasons: {user: [{not_admin?: {username: "admin"}}]})
        MESSAGE

        if ActionPolicy::PrettyPrint.available?
          expect(msg).to include(<<~MESSAGE.strip)
            ↳ user.admin? #=> #{ActionPolicy::PrettyPrint.colorize(true)}
              AND
              check?(:not_admin?) #=> #{ActionPolicy::PrettyPrint.colorize(false)}
          MESSAGE
        end
      end

      failed reason: :unexpected do
        let(:record) { User.new("admin") }
      end
    end
  end
end
