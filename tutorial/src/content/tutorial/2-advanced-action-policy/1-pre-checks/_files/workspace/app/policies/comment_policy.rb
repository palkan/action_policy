class CommentPolicy < ApplicationPolicy
  def destroy?
    record.user_id == user.id || user.admin?
  end
end
