require 'test_helper'

class SearchHelperTest < ActionView::TestCase
  test 'parse_search should return correct qualifiers and search' do
    expected = {
      'normal search' => [[], 'normal search'],
      'score:<1 search text' => [['score:<1'], 'search text'],
      'score:<1 created:>1y multiple qualifiers' => [['score:<1', 'created:>1y'], 'multiple qualifiers'],
      'search with\\: escaped colon' => [[], 'search with: escaped colon']
    }
    expected.each do |input, expect|
      assert_equal ({ qualifiers: expect[0], search: expect[1] }), parse_search(input)
    end
  end

  test 'numeric_value_sql should return correct operator and value' do
    expected = {
      '12345' => ['', '12345'],
      '<12345' => ['<', '12345'],
      '>=12345' => ['>=', '12345']
    }
    expected.each do |input, expect|
      assert_equal expect, numeric_value_sql(input)
    end
  end

  test 'date_value_sql should return correct operator, value, and timeframe' do
    expected = {
      '1' => ['', '1', 'MONTH'],
      '1y' => ['', '1', 'YEAR'],
      '<1y' => ['>', '1', 'YEAR'],
      '>=2w' => ['<=', '2', 'WEEK']
    }
    expected.each do |input, expect|
      assert_equal expect, date_value_sql(input)
    end
  end

  test 'accessible_posts_for should correctly check access' do
    adm_user = users(:admin)
    mod_user = users(:moderator)
    std_user = users(:standard_user)

    adm_posts = accessible_posts_for(adm_user)
    mod_posts = accessible_posts_for(mod_user)
    std_posts = accessible_posts_for(std_user)

    can_admin_get_deleted_posts = adm_posts.any?(&:deleted)
    can_mod_get_deleted_posts = mod_posts.any?(&:deleted)
    can_user_get_deleted_posts = std_posts.any?(&:deleted)

    assert can_admin_get_deleted_posts
    assert can_mod_get_deleted_posts
    assert_not can_user_get_deleted_posts
  end

  test 'qualifiers_to_sql should correctly narrow by :user qualifier' do
    std_user = users(:standard_user)
    edt_user = users(:editor)

    posts_query = accessible_posts_for(std_user)
    edt_post = [{ param: :user, operator: '=', user_id: edt_user.id }]
    edt_query = qualifiers_to_sql(edt_post, posts_query, std_user)

    only_editor_posts = edt_query.to_a.all? { |p| p.user.id == edt_user.id }

    assert_not_equal posts_query.size, edt_query.size
    assert_not_equal edt_query.size, 0
    assert only_editor_posts
  end

  test 'qualifiers_to_sql should correctly narrow by :score qualifier' do
    std_user = users(:standard_user)

    posts_query = accessible_posts_for(std_user)
    bad_post = [{ param: :score, operator: '<', value: 0.5 }]
    good_post = [{ param: :score, operator: '>', value: 0.5 }]
    neut_post = [{ param: :score, operator: '=', value: 0.5 }]

    bad_posts_query = qualifiers_to_sql(bad_post, posts_query, std_user)
    good_posts_query = qualifiers_to_sql(good_post, posts_query, std_user)
    neut_posts_query = qualifiers_to_sql(neut_post, posts_query, std_user)

    only_bad_posts = bad_posts_query.to_a.all? { |p| p.score < 0.5 }
    only_good_posts = good_posts_query.to_a.all? { |p| p.score > 0.5 }
    only_neut_posts = neut_posts_query.to_a.all? { |p| p.score.to_d == 0.5.to_d }

    assert_not_equal posts_query.size, bad_posts_query.size
    assert_not_equal bad_posts_query.size, 0
    assert only_bad_posts

    assert_not_equal posts_query.size, good_posts_query.size
    assert_not_equal good_posts_query.size, 0
    assert only_good_posts

    assert_not_equal posts_query.size, neut_posts_query.size
    assert_not_equal neut_posts_query.size, 0
    assert only_neut_posts
  end

  test 'qualifiers_to_sql should correctly narrow by :status qualifier' do
    std_user = users(:standard_user)

    posts_query = accessible_posts_for(std_user)
    open_post = [{ param: :status, value: 'open' }]
    closed_post = [{ param: :status, value: 'closed' }]

    open_query = qualifiers_to_sql(open_post, posts_query, std_user)
    closed_query = qualifiers_to_sql(closed_post, posts_query, std_user)

    only_open_posts = open_query.to_a.none?(&:closed)
    only_closed_posts = closed_query.to_a.all?(&:closed)

    assert_not_equal posts_query.size, open_query.size
    assert_not_equal open_query.size, 0
    assert only_open_posts

    assert_not_equal posts_query.size, closed_query.size
    assert_not_equal closed_query.size, 0
    assert only_closed_posts
  end

  test 'qualifiers_to_sql should correctly narrow by :upvotes qualifier' do
    std_user = users(:standard_user)

    posts_query = accessible_posts_for(std_user)
    upvoted_post = [{ param: :upvotes, operator: '>', value: 0 }]
    neutral_post = [{ param: :upvotes, operator: '=', value: 0 }]

    upvoted_query = qualifiers_to_sql(upvoted_post, posts_query, std_user)
    neutral_query = qualifiers_to_sql(neutral_post, posts_query, std_user)

    only_upvoted_posts = upvoted_query.to_a.all? { |p| p[:upvote_count].positive? }
    only_neutral_posts = neutral_query.to_a.all? { |p| p[:upvote_count].zero? }

    assert_not_equal posts_query.size, upvoted_query.size
    assert_not_equal upvoted_query.size, 0
    assert only_upvoted_posts

    assert_not_equal posts_query.size, neutral_query.size
    assert_not_equal neutral_query.size, 0
    assert only_neutral_posts
  end

  test 'qualifiers_to_sql should correctly narrow by :downvotes qualifier' do
    std_user = users(:standard_user)

    posts_query = accessible_posts_for(std_user)
    downvoted_post = [{ param: :downvotes, operator: '>', value: 0 }]
    neutral_post = [{ param: :downvotes, operator: '=', value: 0 }]

    downvoted_query = qualifiers_to_sql(downvoted_post, posts_query, std_user)
    neutral_query = qualifiers_to_sql(neutral_post, posts_query, std_user)

    only_downvoted_posts = downvoted_query.to_a.all? { |p| p[:downvote_count].positive? }
    only_neutral_posts = neutral_query.to_a.all? { |p| p[:downvote_count].zero? }

    assert_not_equal posts_query.size, downvoted_query.size
    assert_not_equal downvoted_query.size, 0
    assert only_downvoted_posts

    assert_not_equal posts_query.size, neutral_query.size
    assert_not_equal neutral_query.size, 0
    assert only_neutral_posts
  end
end
