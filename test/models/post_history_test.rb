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
end
