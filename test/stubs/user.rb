# frozen_string_literal: true

class User
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def admin?
    name == "admin"
  end
end

class UserPolicy < ActionPolicy::Base
  verify :user

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
