require 'test_helper'

class SearchQualifierHelperTest < ActionView::TestCase
  test 'matches_id? should correctly match ids' do
    ['123', '>=42', '<8'].each do |value|
      assert matches_id?(value)
    end

    ['name', '3.14', '<=~', '-category'].each do |value|
      assert_not matches_id?(value)
    end
  end

  test 'matches_int? should correctly match integers' do
    ['123', '>=42', '<8', '-404'].each do |value|
      assert matches_int?(value)
    end

    ['name', '3.14', '<=~', '-tag'].each do |value|
      assert_not matches_int?(value)
    end
  end

  test 'matches_numeric? should correctly match numeric values' do
    ['123', '>=42', '3.14'].each do |value|
      assert matches_numeric?(value)
    end

    ['name', '-tag', '>-404'].each do |value|
      assert_not matches_numeric?(value)
    end
  end

  test 'matches_non_negative_int? should correctly match positive ints' do
    ['123', '>=42', '9999', '0'].each do |value|
      assert matches_non_negative_int?(value)
    end

    ['name', '-tag', '3.14', '-273'].each do |value|
      assert_not matches_non_negative_int?(value)
    end
  end

  test 'matches_status? should correctly match status' do
    ['any', 'closed', 'open'].each do |value|
      assert matches_status?(value)
    end

    ['name', '-category', '42'].each do |value|
      assert_not matches_status?(value)
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

  test 'parse_answers_qualifier should correctly parse answers:' do
    [
      ['0', '=', 0],
      ['>2', '>', 2],
      ['<=5', '<=', 5]
    ].each do |entry|
      value, expected_op, expected_val = entry

      parsed = parse_answers_qualifier(value)
      assert_equal :answers, parsed[:param]
      assert_equal expected_op, parsed[:operator]
      assert_equal expected_val, parsed[:value]
    end
  end

  test 'parse_category_qualifier should correctly parse category:' do
    ['=', '>', '<', '<='].each do |operator|
      categories.each do |cat|
        value = operator == '=' ? cat.id.to_s : "#{operator}#{cat.id}"

        parsed = parse_category_qualifier(value)
        assert_equal :category, parsed[:param]
        assert_equal operator, parsed[:operator]
        assert_equal cat.id, parsed[:category_id]
      end
    end
  end

  test 'parse_post_type_qualifier should correctly parse post_type:' do
    ['=', '>', '<', '<='].each do |operator|
      post_types.each do |type|
        value = operator == '=' ? type.id.to_s : "#{operator}#{type.id}"

        parsed = parse_post_type_qualifier(value)
        assert_equal :post_type, parsed[:param]
        assert_equal operator, parsed[:operator]
        assert_equal type.id, parsed[:post_type_id]
      end
    end
  end

  test 'parse_downvotes_qualifier should correctly parse downvotes:' do
    [
      ['42', '=', 42],
      ['>5', '>', 5],
      ['<=1', '<=', 1],
      ['<3', '<', 3]
    ].each do |entry|
      value, expected_op, expected_val = entry

      parsed = parse_downvotes_qualifier(value)
      assert_equal :downvotes, parsed[:param]
      assert_equal expected_op, parsed[:operator]
      assert_equal expected_val, parsed[:value]
    end
  end

  test 'parse_upvotes_qualifier should correctly parse upvotes:' do
    [
      ['42', '=', 42],
      ['>5', '>', 5],
      ['<=1', '<=', 1],
      ['<3', '<', 3]
    ].each do |entry|
      value, expected_op, expected_val = entry

      parsed = parse_upvotes_qualifier(value)
      assert_equal :upvotes, parsed[:param]
      assert_equal expected_op, parsed[:operator]
      assert_equal expected_val, parsed[:value]
    end
  end

  test 'parse_status_qualifier should correctly parse status:' do
    ['any', 'closed', 'open'].each do |value|
      parsed = parse_status_qualifier(value)
      assert_equal :status, parsed[:param]
      assert_equal value, parsed[:value]
    end
  end

  test 'parse_include_tag_qualifier should correctly parse tag:' do
    tags.each do |tag|
      parsed = parse_include_tag_qualifier(tag.name)
      assert_equal :include_tag, parsed[:param]

      parsed_tag = parsed[:tag_id].first
      assert_equal tag.id, parsed_tag.id
    end
  end

  test 'parse_exclude_tag_qualifier should correctly parse -tag:' do
    tags.each do |tag|
      parsed = parse_exclude_tag_qualifier(tag.name)
      assert_equal :exclude_tag, parsed[:param]

      parsed_tag = parsed[:tag_id].first
      assert_equal tag.id, parsed_tag.id
    end
  end

  test 'parse_user_qualifier should correctly parse user:' do
    users.each do |user|
      parsed = parse_user_qualifier(user.id.to_s)
      assert_equal :user, parsed[:param]
      assert_equal user.id, parsed[:user_id]
    end
  end

  test 'parse_votes_qualifier should correctly parse votes:' do
    ['=', '>', '<', '<='].each do |operator|
      ['42', '0'].each do |votes|
        value = "#{operator}#{votes}"

        parsed = parse_votes_qualifier(value)
        assert_equal :net_votes, parsed[:param]
        assert_equal operator, parsed[:operator]
        assert_equal votes.to_i, parsed[:value]
      end
    end
  end
end
