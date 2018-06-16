class AnnouncementPolicy < ActionPolicy::Base
  authorize :user, allow_nil: true

  def show?
    false
  end
end
