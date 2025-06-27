require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'deleting a post should delete its children as well' do
    sign_in users(:global_admin)

    parent = posts(:question_one)

    assert_not_equal(0, parent.children.undeleted)

    post :delete, params: { id: parent }
    parent.reload

    assert_response(:found)
    assert_equal(0, parent.children.undeleted.size)
  end
end
