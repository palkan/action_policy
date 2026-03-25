class CommentPolicy < ApplicationPolicy
  authorize :ticket, optional: true

  relation_scope do |relation|
    next relation unless user.customer?

    relation.where(internal: false)
  end

  def show?
    !record.internal? || user.agent?
  end

  def create?
    user.agent? || ticket&.open? || ticket&.in_progress?
  end

  def destroy?
    record.user_id == user.id
  end
end
