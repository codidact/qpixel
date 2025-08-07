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
end
