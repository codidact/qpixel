require 'test_helper'

class PostTest < ActiveSupport::TestCase
  test "deleting a post should remove reputation change" do
    post = posts(:answer_one)
    previous_rep = post.user.reputation
    expected_change = Vote.total_rep_change(post.votes)
    post.update(deleted: true)
    assert_equal previous_rep - expected_change, post.user.reputation
  end

  test "undeleting a post should restore reputation change" do
    post = posts(:answer_one)
    post.update(deleted: true)

    previous_rep = post.user.reputation
    expected_change = Vote.total_rep_change(post.votes)
    post.update(deleted: false)
    assert_equal previous_rep + expected_change, post.user.reputation
  end

  test "deleting an old post should not remove reputation change" do
    post = posts(:really_old_answer)
    previous_rep = post.user.reputation
    post.update(deleted: true)
    assert_equal previous_rep, post.user.reputation
  end

  test "adding an answer should increase answer_count" do
    question = posts(:question_one)
    pre_count = question.answer_count
    Post.create(body_markdown: 'abcde fghij klmno pqrst uvwxyz', body: '<p>abcde fghij klmno pqrst uvwxyz</p>',
                score: 0, user: users(:standard_user), parent: question, post_type_id: Answer.post_type_id)
    post_count = question.answer_count
    assert_equal pre_count + 1, post_count
  end
end
