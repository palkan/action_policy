class Groups::AnnouncementPolicy < ActionPolicy::Base
  authorize :user, allow_nil: true

  def show?
    true
  end
end
