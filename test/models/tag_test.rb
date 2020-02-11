require 'test_helper'

class TagTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is community related' do
    assert_community_related(Tag)
  end
end
