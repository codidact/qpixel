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
end
