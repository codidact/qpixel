require 'test_helper'

class PrivilegeTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is commmunity related' do
    assert_community_related(Privilege)
  end

end
