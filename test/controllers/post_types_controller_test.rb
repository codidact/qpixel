require 'test_helper'

class PostTypesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can get index' do
    sign_in users(:global_admin)
    get :index
    assert_response(:success)
    assert_not_nil assigns(:types)
  end

  test 'index requires auth' do
    get :index
    assert_redirected_to_sign_in
  end

  test 'index requires global admin' do
    sign_in users(:admin)
    get :index
    assert_response(:not_found)
  end

  test 'can get new' do
    sign_in users(:global_admin)
    get :new
    assert_response(:success)
    assert_not_nil assigns(:type)
  end

  test 'new requires auth' do
    get :new
    assert_redirected_to_sign_in
  end

  test 'new requires global admin' do
    sign_in users(:admin)
    get :new
    assert_response(:not_found)
  end

  test 'can create post type' do
    sign_in users(:global_admin)
    data = { name: 'Test Type', description: 'words', icon_name: 'heart',
      has_answers: true, has_license: true, has_category: true,
      answer_type_id: Answer.post_type_id, has_reactions: false,
      has_only_specific_reactions: true }
    post :create, params: { post_type: data }
    assert_response(:found)
    assert_redirected_to post_types_path

    # Test, if the correct values are applied
    assert_not_nil assigns(:type)
    data.each do |k, v|
      assert_equal v, assigns(:type).send(k)
    end
  end

  test 'create requires auth' do
    post :create, params: { post_type: { name: 'Test Type', description: 'words', icon_name: 'heart',
                                         has_answers: 'true', has_license: 'true', has_category: 'true' } }
    assert_redirected_to_sign_in
  end

  test 'create requires global admin' do
    sign_in users(:admin)
    post :create, params: { post_type: { name: 'Test Type', description: 'words', icon_name: 'heart',
                                         has_answers: 'true', has_license: 'true', has_category: 'true' } }
    assert_response(:not_found)
  end

  test 'can get edit' do
    sign_in users(:global_admin)
    get :edit, params: { id: post_types(:question).id }
    assert_response(:success)
    assert_not_nil assigns(:type)
  end

  test 'edit requires auth' do
    get :edit, params: { id: post_types(:question).id }
    assert_redirected_to_sign_in
  end

  test 'edit requires global admin' do
    sign_in users(:admin)
    get :edit, params: { id: post_types(:question).id }
    assert_response(:not_found)
  end

  test 'can update post type' do
    sign_in users(:global_admin)

    data = { name: 'Test Type',
             description: 'words',
             icon_name: 'heart',
             has_answers: true,
             has_license: true,
             has_category: true,
             answer_type_id: Answer.post_type_id,
             has_reactions: false,
             has_only_specific_reactions: true }

    try_update_post_type(post_types(:question), **data)

    assert_response(:found)
    assert_redirected_to post_types_path

    # Test, if the correct values are applied
    assert_not_nil assigns(:type)
    data.each do |k, v|
      assert_equal v, assigns(:type).send(k)
    end
  end

  test 'update requires auth' do
    try_update_post_type(post_types(:question))
    assert_redirected_to_sign_in
  end

  test 'update requires global admin' do
    sign_in users(:admin)
    try_update_post_type(post_types(:question))
    assert_response(:not_found)
  end

  private

  # @param post_type [PostType] post type to update
  # @param opts
  def try_update_post_type(post_type, **opts)
    patch :update, params: { post_type: { name: 'Test Type',
                                          description: 'words',
                                          icon_name: 'heart',
                                          has_answers: 'true',
                                          has_license: 'true',
                                          has_category: 'true' }.merge(opts),
                             id: post_type.id }
  end
end
