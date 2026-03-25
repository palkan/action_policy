class CommentPolicy < ApplicationPolicy
  authorize :ticket, optional: true

  def create?
    user.agent? || ticket&.open? || ticket&.in_progress?
  end

  def destroy?
    record.user_id == user.id
  end
end
