require 'test_helper'

class SuggestedEditTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is commmunity related' do
    assert_community_related(SuggestedEdit)
  end

  test 'is post related' do
    assert_post_related(SuggestedEdit)
  end

  test 'status helpers work correctly' do
    assert suggested_edits(:pending_suggested_edit).pending?
    assert suggested_edits(:accepted_suggested_edit).approved?
    assert suggested_edits(:rejected_suggested_edit).rejected?
  end
end
