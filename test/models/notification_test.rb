require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is community related' do
    assert_community_related(Notification)
  end
end
