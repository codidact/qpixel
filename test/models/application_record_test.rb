require 'test_helper'

class ApplicationRecordTest < ActiveSupport::TestCase
  test 'sanitize_for_exclusion_search should correctly invert all words' do
    [
      ['-one -two -three --four', 'one two three four']
    ].each do |test|
      input, expected = test
      assert_equal expected,
                   ApplicationRecord.sanitize_for_exclusion_search(input)
    end
  end

  test 'fuzzy_search should correctly search records' do
    results = Post.fuzzy_search('Q2', posts: [:body_markdown, :title]).map(&:id)
    post_ids = posts.select { |p| /^Q\d+/.match?(p.title) }.map(&:id)
    assert(post_ids.all? { |id| results.include?(id) })
  end
end
