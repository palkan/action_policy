# frozen_string_literal: true

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
  verify :user

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
