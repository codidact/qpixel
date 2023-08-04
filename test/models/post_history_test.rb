require 'test_helper'

class PostHistoryTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is post related' do
    assert_post_related(PostHistory)
  end

  test 'calling an event with insufficient arguments should throw NoMethodError' do
    assert_raises NoMethodError do
      PostHistory.question_closed
    end
    assert_raises NoMethodError do
      PostHistory.question_closed(posts(:question_one))
    end
  end

  test 'calling a nonexistent event should throw NoMethodError' do
    assert_raises NoMethodError do
      PostHistory.nonexistent_history(posts(:question_one), users(:standard_user))
    end
  end

  test 'calling an event without state should leave state nil' do
    post = posts(:question_one)
    event = PostHistory.question_closed(post, users(:closer))
    assert_nil event.before_state
    assert_nil event.after_state
  end

  test 'calling an event with state should include state parameters' do
    post = posts(:question_one)
    event = PostHistory.initial_revision(post, users(:standard_user), after: post.body_markdown)
    assert_not_nil post.body_markdown
    assert_equal post.body_markdown, event.after_state
    assert_nil event.before_state
  end

  test 'edit event matching current post can be rolled back' do
    event = post_histories(:q1_edit)
    assert event.can_rollback?
  end

  test 'if body does not match, edit event cannot be rolled back' do
    event = post_histories(:q1_edit)
    event.update!(after_state: "#{event.after_state} - not matching")
    assert_not event.can_rollback?
  end

  test 'if title does not match, edit event cannot be rolled back' do
    event = post_histories(:q1_edit)
    event.update!(after_title: "#{event.after_title} - not matching")
    assert_not event.can_rollback?
  end

  test 'if after tags are missing on post, edit event cannot be rolled back' do
    event = post_histories(:q1_edit)
    event.post_history_tags.where(relationship: 'after').first.destroy!
    assert_not event.can_rollback?
  end

  test 'if additional unrelated tags are on post, edit event can still be rolled back' do
    event = post_histories(:q1_edit)
    post = event.post
    post.tags_cache << tags(:child).name
    post.save!

    # Refresh event, should still be allowed to rollback
    event = PostHistory.find(event.id)
    assert event.can_rollback?
  end

  test 'predecessor of event finds closest predecessor' do
    event = post_histories(:q1_reopen2)
    assert_equal post_histories(:q1_close2), event.find_predecessor('question_closed')
  end
end
