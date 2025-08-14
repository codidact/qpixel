require 'test_helper'

class FlagTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is post related' do
    assert_post_related(Flag)
  end

  test 'confidential?' do
    normal = flags(:one)
    secret = flags(:confidential_on_deleter)

    assert_equal normal.confidential?, false
    assert_equal secret.confidential?, true
  end

  test 'flags should be correctly validated' do
    SiteSetting['MaxFlagReasonLength'] = 500

    common_attributes = {
      post: posts(:question_one),
      user: users(:standard_user)
    }

    too_long = Flag.new(reason: 'a' * 1000, **common_attributes)
    assert_not too_long.valid?
    assert too_long.errors[:reason].any?

    valid = Flag.new(reason: 'my reasons are my own', **common_attributes)
    assert valid.valid?
  end
end
