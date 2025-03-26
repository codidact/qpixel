require 'test_helper'

class SeedsHelperTest < ActionView::TestCase
  test 'calling SeedsHelper#files with seed_name should constrain paths' do
    files = SeedsHelper.files('posts')

    assert_instance_of Array, files
    assert_equal files.length, 1
    assert_includes files, "#{Dir.pwd}/db/seeds/posts.yml"
  end
end
