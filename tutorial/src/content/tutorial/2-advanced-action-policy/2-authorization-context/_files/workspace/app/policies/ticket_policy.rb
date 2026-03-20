class TicketPolicy < ApplicationPolicy
  def show?
    true
  end

  def manage?
    record.user_id == user.id ||
      (user.agent? && record.agent_id == user.id)
  end

  def destroy? = false
end
