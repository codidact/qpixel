require 'test_helper'

class FlagTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is post related' do
    assert_post_related(Flag)
  end
end
