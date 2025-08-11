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
end
