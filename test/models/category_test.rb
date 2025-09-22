require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  test 'search should correctly narrow down categories by name' do
    categories.each do |category|
      results = Category.search(category.name)

      results.each do |cat|
        assert_equal cat.name, category.name
      end
    end
  end

  test 'search should match any substring in name' do
    results = Category.search('Trust')

    results.each do |cat|
      assert cat.name.include?('Trust')
    end
  end

  test 'public? should correctly determine category visibility' do
    assert categories(:main).public?
    assert_not categories(:admin_only).public?
  end
end
