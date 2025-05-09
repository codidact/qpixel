require 'test_helper'

class PostTypeTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'active_reactions? should correctly check if the post type has active reactions' do
    type_without = post_types(:article)
    type_with = post_types(:answer)

    assert_equal type_without.active_reactions?, false
    assert_equal type_with.active_reactions?, true
  end
end
