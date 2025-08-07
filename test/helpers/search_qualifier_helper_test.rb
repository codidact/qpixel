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

    ['name', '-tag', '3.14'].each do |value|
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

  test 'parse_answers_qualifier should correclty parse answers:' do
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
    [
      ['10', '=', 10],
      ['>2', '>', 2],
      ['<=5', '<=', 5]
    ].each do |entry|
      value, expected_op, expected_val = entry

      parsed = parse_category_qualifier(value)
      assert_equal :category, parsed[:param]
      assert_equal expected_op, parsed[:operator]
      assert_equal expected_val, parsed[:category_id]
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
end
