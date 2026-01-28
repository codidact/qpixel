require 'test_helper'

class TagsHelperTest < ActionView::TestCase
  test 'rendered_wiki should correctly sanitize content' do
    vacuous_wiki_tag = tags(:with_vacuous_wiki)
    vacuous_wiki = rendered_wiki(vacuous_wiki_tag)
    assert vacuous_wiki.blank?

    normal_wiki_tag = tags(:with_wiki)
    normal_wiki = rendered_wiki(normal_wiki_tag)
    assert_equal normal_wiki_tag.wiki, normal_wiki
  end
end
