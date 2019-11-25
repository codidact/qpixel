require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test "parent_question should return question for a comment on an answer" do
    assert_equal posts(:question_one).id, comments(:on_answer).parent_question.id
  end

  test "parent_question should return nil for a comment on a question" do
    assert_nil comments(:one).parent_question
  end

  test "root should return question for comments on any post" do
    assert_equal posts(:question_one).id, comments(:one).root.id
    assert_equal posts(:question_one).id, comments(:on_answer).root.id
  end
end
