require 'test_helper'

class CommentThreadTest < ActiveSupport::TestCase
  test 'should correctly validate titles' do
    valid_title = 'should pass all validations'

    ['', 'a' * 512, valid_title].each do |title|
      thread = CommentThread.new(post: posts(:question_one), title: title)
      is_valid = thread.valid?

      assert_equal valid_title == title, is_valid

      unless is_valid
        assert thread.errors[:title].any?
      end
    end
  end

  test 'last_activity should correctly get the thread\'s last activity date & time' do
    thread = comment_threads(:without_activity)

    assert_equal thread.created_at, thread.last_activity

    thread.update!(title: 'this should bump last_activity')
    thread.reload
    last_activity_after_update = thread.last_activity
    assert_operator thread.updated_at, '<=', last_activity_after_update

    thread.bump_last_activity
    last_activity_after_bump = thread.last_activity
    assert_operator last_activity_after_update, '<=', last_activity_after_bump

    thread.add_follower(users(:editor))
    thread.reload
    assert_operator last_activity_after_bump, '<=', thread.last_activity
  end
end
