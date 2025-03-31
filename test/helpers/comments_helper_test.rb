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

  test 'comment_rate_limited prevents new users commenting on others posts' do
    rate_limited, limit_message = comment_rate_limited? users(:basic_user), posts(:question_one)
    assert_equal true, rate_limited
    assert_equal 'As a new user, you can only comment on your own posts and on answers to them.', limit_message
  end

  test 'comment_rate_limited allows new user to comment on own post' do
    rate_limited, limit_message = comment_rate_limited? users(:basic_user), posts(:new_user_question)
    assert_equal false, rate_limited
    assert_equal nil, limit_message
  end
end
