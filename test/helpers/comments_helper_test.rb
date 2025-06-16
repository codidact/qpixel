require 'test_helper'

class CommentsHelperTest < ActionView::TestCase
  include Devise::Test::ControllerHelpers

  test '[help center] and [help] substitution' do
    expected = {
      '[help] me' => "<a href=\"#{help_center_url}\">help</a> me",
      'visit the [help center]' => "visit the <a href=\"#{help_center_url}\">help center</a>",
      'you cannot be [helped]' => 'you cannot be [helped]'
    }
    expected.each do |input, expect|
      assert_equal expect, render_comment_helpers(+input, users(:standard_user))
    end
  end

  test '[votes?] substitution' do
    expected = {
      'i have a [vote]' => "i have a <a href=\"#{my_vote_summary_url}\">vote</a>",
      'and many other [votes] too' => "and many other <a href=\"#{my_vote_summary_url}\">votes</a> too",
      'i really like [voting]' => 'i really like [voting]'
    }
    expected.each do |input, expect|
      assert_equal expect, render_comment_helpers(+input, users(:standard_user))
    end
  end

  test '[flags?] substitution' do
    expected = {
      '[flag] me if you can' => "<a href=\"#{flag_history_url(users(:standard_user).id)}\">flag</a> me if you can",
      '\'cause it\'s our [flags]hip product' => "'cause it's our <a href=\"#{flag_history_url(users(:standard_user).id)}\">flags</a>hip product",
      'yeah bad pun - [flagged] and downvoted' => 'yeah bad pun - [flagged] and downvoted'
    }
    expected.each do |input, expect|
      assert_equal expect, render_comment_helpers(+input, users(:standard_user))
    end
  end

  test '[category] substitutions' do
    expected = {
      'you can go to [category:main]' => "you can go to <a href=\"#{category_url(categories(:main).id)}\">Main</a>",
      'or [category:Meta]' => "or <a href=\"#{category_url(categories(:meta).id)}\">Meta</a>",
      "maybe even to [category##{categories(:high_trust).id}]" => \
        "maybe even to <a href=\"#{category_url(categories(:high_trust).id)}\">High Trust</a>",
      'but not to [category:blah]' => 'but not to [category:blah]'
    }
    expected.each do |input, expect|
      assert_equal expect, render_comment_helpers(+input, users(:standard_user))
    end
  end

  test 'comment_rate_limited? should prevent users that reached the daily limit from commenting' do
    basic = users(:basic_user)
    std = users(:standard_user)
    own_post = posts(:question_one)
    other_post = posts(:question_two)

    SiteSetting['RL_NewUserComments'] = 0
    SiteSetting['RL_NewUserCommentsOwnPosts'] = 0
    SiteSetting['RL_Comments'] = 0
    SiteSetting['RL_CommentsOwnPosts'] = 0

    [basic, std].each do |user|
      [own_post, other_post].each do |post|
        rate_limited, limit_message = comment_rate_limited?(user, post)
        assert_equal true, rate_limited
        assert_not_nil limit_message

        log = AuditLog.where(event_type: 'comment', related: post, user: user).order(created_at: :desc).first
        assert log.present?, 'Expected audit log for attempting to comment on a post while rate-limited to be created'
      end
    end
  end

  test 'comment_rate_limited? should allow users to comment on their own posts' do
    basic = users(:basic_user)
    std = users(:standard_user)

    SiteSetting['RL_NewUserCommentsOwnPosts'] = 50

    rate_limited, limit_message = comment_rate_limited?(basic, posts(:new_user_question))
    assert_equal false, rate_limited
    assert_nil limit_message

    SiteSetting['RL_CommentsOwnPosts'] = 50

    rate_limited, limit_message = comment_rate_limited?(std, posts(:question_one))
    assert_equal false, rate_limited
    assert_nil limit_message
  end

  test 'comment_rate_limited? should allow users to comment on posts of others' do
    basic = users(:basic_user)
    std = users(:standard_user)
    other_post = posts(:question_two)

    SiteSetting['RL_NewUserComments'] = 50
    SiteSetting['RL_Comments'] = 50

    [basic, std].each do |user|
      rate_limited, limit_message = comment_rate_limited?(user, other_post)
      assert_equal false, rate_limited
      assert_nil limit_message
    end
  end
end
