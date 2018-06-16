require 'test_helper'
require 'action_policy/test_helper'

class Groups::AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  include ActionPolicy::TestHelper

  def test_show
    assert_authorized_to(:show?, Announcement, with: Groups::AnnouncementPolicy) do
      get groups_announcement_path(1)
    end
  end
end
