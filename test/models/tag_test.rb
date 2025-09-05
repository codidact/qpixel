require 'test_helper'

class TagTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is community related' do
    assert_community_related(Tag)
  end

  test 'search should correctly order tags' do
    term = 'us'

    tags = Tag.search(term).to_a

    name_match_sorted = tags.select { |t| t.name.include?(term) }.sort { |a, b| a.name <=> b.name }
    excerpt_match_sorted = tags.select { |t| t.excerpt&.include?(term) }.sort { |a, b| a.name <=> b.name }
    sorted_tags = name_match_sorted + excerpt_match_sorted

    sorted_tags.each_with_index do |tag, idx|
      assert_equal tag.name, tags[idx].name
    end
  end
end
