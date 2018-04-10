# frozen_string_literal: true

class Account
  include Comparable

  attr_reader :type

  def initialize(type)
    @type = type
  end

  def admin?
    type == "admin"
  end

  def <=>(other)
    return super unless other.is_a?(Account)
    name <=> other.name
  end
end

class AccountPolicy < ActionPolicy::Base
  def create?
    user.admin?
  end

  def manage?
    !record.admin? || user.admin?
  end
end
