require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is post related' do
    assert_post_related(Comment)
  end

  test 'parent_question should return question for a comment on an answer' do
    assert_equal posts(:question_one).id, comments(:on_answer).parent_question.id
  end

  test 'parent_question should return nil for a comment on a question' do
    assert_nil comments(:one).parent_question
  end

  test 'root should return question for comments on any post' do
    assert_equal posts(:question_one).id, comments(:one).root.id
    assert_equal posts(:question_one).id, comments(:on_answer).root.id
  end

  test 'USER_PING_REG_EXP should correctly match user mentions' do
    valid_mentions = ["@##{User.system.id}", "@##{users(:standard_user).id}"]

    valid_mentions.each do |mention|
      assert Comment::USER_PING_REG_EXP.match?(mention)
    end

    invalid_mentions = ['', '@', '@#', '@#system', "@##{users(:standard_user).name}"]

    invalid_mentions.each do |mention|
      assert_not Comment::USER_PING_REG_EXP.match?(mention)
    end
  end

  test 'pings should correctly get pinged user ids' do
    std_user = users(:standard_user)
    with_pings = comments(:with_user_pings)

    pings = with_pings.pings

    assert pings.include?(std_user.id)
    assert_not pings.include?(User.system.id)
  end

  test 'last_activity should correctly get the comment\'s last activity date & time' do
    comment = comments(:without_activity)

    assert_equal comment.created_at, comment.last_activity

    comment.update!(content: 'this should bump last_activity')
    comment.reload
    last_activity_after_update = comment.last_activity
    assert_operator comment.updated_at, '<=', last_activity_after_update

    comment.bump_last_activity
    assert_operator last_activity_after_update, '<=', comment.last_activity
  end
end
