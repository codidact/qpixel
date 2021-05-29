require 'test_helper'

class PostTypesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can get index' do
    sign_in users(:global_admin)
    get :index
    assert_response 200
    assert_not_nil assigns(:types)
  end

  test 'index requires auth' do
    get :index
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'index requires global admin' do
    sign_in users(:admin)
    get :index
    assert_response 404
  end

  test 'can get new' do
    sign_in users(:global_admin)
    get :new
    assert_response 200
    assert_not_nil assigns(:type)
  end

  test 'new requires auth' do
    get :new
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'new requires global admin' do
    sign_in users(:admin)
    get :new
    assert_response 404
  end

  test 'can create post type' do
    sign_in users(:global_admin)
    post :create, params: { post_type: { name: 'Test Type', description: 'words', icon_name: 'heart',
                                         has_answers: 'true', has_license: 'true', has_category: 'true' } }
    assert_response 302
    assert_redirected_to post_types_path
  end

  test 'create requires auth' do
    post :create, params: { post_type: { name: 'Test Type', description: 'words', icon_name: 'heart',
                                         has_answers: 'true', has_license: 'true', has_category: 'true' } }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'create requires global admin' do
    sign_in users(:admin)
    post :create, params: { post_type: { name: 'Test Type', description: 'words', icon_name: 'heart',
                                         has_answers: 'true', has_license: 'true', has_category: 'true' } }
    assert_response 404
  end

  test 'can get edit' do
    sign_in users(:global_admin)
    get :edit, params: { id: post_types(:question).id }
    assert_response 200
    assert_not_nil assigns(:type)
  end

  test 'edit requires auth' do
    get :edit, params: { id: post_types(:question).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'edit requires global admin' do
    sign_in users(:admin)
    get :edit, params: { id: post_types(:question).id }
    assert_response 404
  end

  test 'can update post type' do
    sign_in users(:global_admin)
    patch :update, params: { post_type: { name: 'Test Type', description: 'words', icon_name: 'heart',
                                          has_answers: 'true', has_license: 'true', has_category: 'true' },
                             id: post_types(:question).id }
    assert_response 302
    assert_redirected_to post_types_path
  end

  test 'update requires auth' do
    patch :update, params: { post_type: { name: 'Test Type', description: 'words', icon_name: 'heart',
                                          has_answers: 'true', has_license: 'true', has_category: 'true' },
                             id: post_types(:question).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'update requires global admin' do
    sign_in users(:admin)
    patch :update, params: { post_type: { name: 'Test Type', description: 'words', icon_name: 'heart',
                                          has_answers: 'true', has_license: 'true', has_category: 'true' },
                             id: post_types(:question).id }
    assert_response 404
  end
end
