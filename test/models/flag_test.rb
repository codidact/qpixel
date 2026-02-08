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

  test 'accessible_to should correctly scope flags' do
    std = users(:standard_user)
    del = users(:deleter)
    mod = users(:moderator)

    [std, del, mod].each do |user|
      flags = Flag.accessible_to(user, posts(:question_one))
      assert_equal user.same_as?(std), flags.none?
    end

    assert Flag.accessible_to(mod, posts(:deleted)).any?(&:confidential?)
    assert_not Flag.accessible_to(del, posts(:deleted)).any?(&:confidential?)
  end
end
