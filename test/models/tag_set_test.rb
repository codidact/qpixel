require 'test_helper'

class TagSetTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is community related' do
    assert_community_related(TagSet)
  end

  test 'with_paths method should respect no_excerpt' do
    main = TagSet.main

    all = main.with_paths.size
    excerptless = main.with_paths(true).size

    assert_not_equal(all, excerptless)
  end
end
