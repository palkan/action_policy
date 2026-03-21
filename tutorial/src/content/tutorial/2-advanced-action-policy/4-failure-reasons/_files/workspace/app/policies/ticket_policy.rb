class TicketPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if user.admin?
    next relation.where(agent_id: [user.id, nil]) if user.agent?

    relation.where(user_id: user.id)
  end

  def show?
    true
  end

  def manage?
    record.user_id == user.id ||
      (user.agent? && record.agent_id == user.id)
  end

  def destroy? = false

  def resolve?
    user.agent?
  end
end
