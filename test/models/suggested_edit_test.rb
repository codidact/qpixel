require 'test_helper'

class SuggestedEditTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is community related' do
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

  test 'accessible_to should correctly scope suggested edits' do
    categories_with_edits_on_deleted_posts = suggested_edits
                                             .select { |edit| edit.post.deleted? }
                                             .map { |edit| edit.post.category.id }
                                             .uniq

    assert categories_with_edits_on_deleted_posts.any?

    users.each do |user|
      categories_with_edits_on_deleted_posts.each do |category|
        edits = SuggestedEdit.accessible_to(user, category)

        assert edits.any?

        if user.can_see_deleted_posts?
          assert(edits.any? { |edit| edit.post.deleted? })
        else
          assert(edits.none? { |edit| edit.post.deleted? })
        end
      end
    end
  end
end
