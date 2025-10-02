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

  test 'qualifiers_to_sql should correctly narrow by :category qualifier' do
    main = categories(:main)
    admin_only = categories(:admin_only)

    std_user = users(:standard_user)
    adm_user = users(:admin)

    posts_query_std = Post.accessible_to(std_user)
    posts_query_adm = Post.accessible_to(adm_user)

    std_post = [{ param: :category, operator: '=', category_id: main.id }]
    adm_post = [{ param: :category, operator: '=', category_id: admin_only.id }]

    std_posts_query_standard = qualifiers_to_sql(std_post, posts_query_std, std_user)
    adm_posts_query_standard = qualifiers_to_sql(adm_post, posts_query_std, std_user)
    adm_posts_query_admin = qualifiers_to_sql(adm_post, posts_query_adm, adm_user)

    assert_not_equal posts_query_std.size, std_posts_query_standard.size
    assert_not_equal std_posts_query_standard.size, 0

    assert_not_equal posts_query_adm.size, adm_posts_query_admin.size
    assert_not_equal adm_posts_query_admin.size, 0

    assert_equal adm_posts_query_standard.size, 0
  end

  test 'qualifiers_to_sql should correctly narrow by :user qualifier' do
    std_user = users(:standard_user)
    edt_user = users(:editor)

    posts_query = Post.accessible_to(std_user)
    edt_post = [{ param: :user, operator: '=', user_id: edt_user.id }]
    edt_query = qualifiers_to_sql(edt_post, posts_query, std_user)

    only_editor_posts = edt_query.to_a.all? { |p| p.user.id == edt_user.id }

    assert_not_equal posts_query.size, edt_query.size
    assert_not_equal edt_query.size, 0
    assert only_editor_posts
  end

  test 'qualifiers_to_sql should correctly narrow by :score qualifier' do
    std_user = users(:standard_user)

    posts_query = Post.accessible_to(std_user)
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

  test 'qualifiers_to_sql should correctly narrow by :source qualifier' do
    std_user = users(:standard_user)

    posts_query = Post.accessible_to(std_user)
    native_post = [{ param: :source, value: :native }]
    imported_post = [{ param: :source, value: :imported }]

    native_query = qualifiers_to_sql(native_post, posts_query, std_user)
    imported_query = qualifiers_to_sql(imported_post, posts_query, std_user)

    only_native_posts = native_query.to_a.none?(&:imported?)
    only_imported_posts = imported_query.to_a.all?(&:imported?)

    assert_not_equal posts_query.size, native_query.size
    assert_not_equal native_query.size, 0
    assert only_native_posts

    assert_not_equal posts_query.size, imported_query.size
    assert_not_equal imported_query.size, 0
    assert only_imported_posts
  end

  test 'qualifiers_to_sql should correctly narrow by :status qualifier' do
    std_user = users(:standard_user)

    posts_query = Post.accessible_to(std_user)
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

    posts_query = Post.accessible_to(std_user)
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

    posts_query = Post.accessible_to(std_user)
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

  test 'qualifiers_to_sql should correctly narrow by :net_votes qualifier' do
    std_user = users(:standard_user)

    posts_query = Post.accessible_to(std_user)
    divisive_post = [{ param: :net_votes, operator: '=', value: 2 }]

    divisive_query = qualifiers_to_sql(divisive_post, posts_query, std_user)

    only_divisive_posts = divisive_query.to_a.all? do |p|
      (p[:upvote_count] - p[:downvote_count]) == 2
    end

    assert_not_equal posts_query.size, divisive_query.size
    assert_not_equal divisive_query.size, 0
    assert only_divisive_posts
  end

  test 'search_posts should not show posts in categories that a user cannot view' do
    std_user = users(:standard_user)

    params = ActionController::Parameters.new({ search: 'high trust' })
    posts, _qualifiers = search_posts(std_user, params)

    admin_category = categories(:admin_only)

    assert_not(posts.any? { |p| p.category.id == admin_category.id })
  end
end
