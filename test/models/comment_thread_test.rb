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

  test 'last_activity_at should correctly get last activity' do
    normal = comment_threads(:normal)
    normal_two = comment_threads(:normal_two)
    locked = comment_threads(:locked)

    assert_not_equal locked.last_activity_at, locked.created_at
    assert_not_equal normal_two.last_activity_at, normal_two.created_at

    assert_equal locked.last_activity_at, locked.locked_at
    assert_equal normal.last_activity_at, normal.created_at
    assert_equal normal_two.last_activity_at, normal_two.updated_at
  end
end
