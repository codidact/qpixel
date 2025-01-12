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
    admin_user = users(:admin)
    mod_user = users(:moderator)
    standard_user = users(:standard_user)

    admin_posts = accessible_posts_for(admin_user)
    mod_posts = accessible_posts_for(mod_user)
    user_posts = accessible_posts_for(standard_user)

    can_admin_get_deleted_posts = admin_posts.any?(&:deleted)
    can_mod_get_deleted_posts = mod_posts.any?(&:deleted)
    can_user_get_deleted_posts = user_posts.any?(&:deleted)

    assert can_admin_get_deleted_posts
    assert can_mod_get_deleted_posts
    assert_not can_user_get_deleted_posts
  end

  test 'qualifiers_to_sql should correctly narrow by :user qualifier' do
    standard_user = users(:standard_user)
    editor_user = users(:editor)

    posts_query = accessible_posts_for(standard_user)

    eq_editor = [{ param: :user, operator: '=', user_id: editor_user.id }]
    qualified_query = qualifiers_to_sql(eq_editor, posts_query, standard_user)

    is_owner_editor = qualified_query.to_a.all? { |p| p.user.id == editor_user.id }

    assert_not_equal posts_query.size, qualified_query.size
    assert_not_equal qualified_query.size, 0
    assert is_owner_editor
  end
end
