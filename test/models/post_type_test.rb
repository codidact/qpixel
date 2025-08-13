require 'test_helper'

class PostTypeTest < ActiveSupport::TestCase
  test 'system? should correctly determine if a type is a system type' do
    assert_not post_types(:question).system?
    assert post_types(:policy_doc).system?
    assert post_types(:help_doc).system?
  end
end
