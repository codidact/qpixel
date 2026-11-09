require 'test_helper'

class TagTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is community related' do
    assert_community_related(Tag)
  end

  test 'search should correctly order tags' do
    term = 'us'

    tags = Tag.search(term).to_a

    name_match_sorted = tags.select { |t| t.name.include?(term) }.sort { |a, b| a.name.length <=> b.name.length }
    excerpt_match_sorted = tags.select { |t| t.excerpt&.include?(term) }.sort { |a, b| a.name <=> b.name }
    sorted_tags = name_match_sorted + excerpt_match_sorted

    sorted_tags.each_with_index do |tag, idx|
      assert_equal tag.name, tags[idx].name
    end
  end

  test 'each_upwards should correctly traverse tag chains' do
    tag = tags(:chain_l3)

    expected = tag
    Tag.each_upwards(tag.id) do |tag|
      assert_equal expected.id, tag.id,
                   "Expected \"#{expected.name}\", got \"#{tag.name}\""
      expected = tag.parent
    end
  end

  test 'all_children should correctly build tag chains' do
    root_tag = tags(:chain_l1)

    l2, l3 = root_tag.all_children

    assert_equal tags(:chain_l2).id, l2
    assert_equal tags(:chain_l3).id, l3
    assert Rails.cache.exist?("tags/#{root_tag.id}/all_children")
  end

  test 'reparenting a tag should clear children cache for its parents' do
    chained = tags(:chain_l1, :chain_l2, :chain_l3)

    chained.each do |tag|
      tag.all_children
      assert Rails.cache.exist?("tags/#{tag.id}/all_children")
    end

    chained.third.update(parent: tags(:base))

    assert Rails.cache.exist?("tags/#{chained.third.id}/all_children")

    chained[0..1].each do |tag|
      assert_not Rails.cache.exist?("tags/#{tag.id}/all_children")
    end
  end

  test 'destroying a tag should clear children cache for it & its parents' do
    chained = tags(:chain_l1, :chain_l2, :chain_l3)

    chained.each do |tag|
      tag.all_children
      assert Rails.cache.exist?("tags/#{tag.id}/all_children")
    end

    chained.third.destroy

    chained.each do |tag|
      assert_not Rails.cache.exist?("tags/#{tag.id}/all_children")
    end
  end
end
