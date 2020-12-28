require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can get edit' do
    sign_in users(:standard_user)
    get :edit, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  test 'edit requires authentication' do
    get :edit, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'cannot edit locked post' do
    sign_in users(:standard_user)
    get :edit, params: { id: posts(:locked).id }
    assert_response 403
  end

  test 'cannot edit non-public post without permissions' do
    sign_in users(:standard_user)
    get :edit, params: { id: posts(:blog_post).id }
    assert_response 302
    assert_redirected_to root_path
    assert_not_nil flash[:danger]
  end

  test 'author can edit non-public post' do
    sign_in users(:closer)
    get :edit, params: { id: posts(:blog_post).id }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  test 'moderator can edit non-public post' do
    sign_in users(:moderator)
    get :edit, params: { id: posts(:blog_post).id }
    assert_response 200
    assert_not_nil assigns(:post)
  end
end
