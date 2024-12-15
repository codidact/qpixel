require 'test_helper'

class TagSetTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is community related' do
    assert_community_related(TagSet)
  end
end
