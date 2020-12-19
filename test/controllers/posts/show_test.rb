require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'anonymous user can get show' do
    get :show, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:children)
    assert_not assigns(:children).any?(&:deleted), 'Anonymous user can see deleted answers'
  end

  test 'standard user can get show' do
    sign_in users(:standard_user)
    get :show, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:children)
    assert_not assigns(:children).any?(&:deleted), 'Anonymous user can see deleted answers'
  end

  test 'privileged user can see deleted post' do
    sign_in users(:deleter)
    get :show, params: { id: posts(:deleted).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:children)
  end

  test 'privileged user can see deleted answers' do
    sign_in users(:deleter)
    get :show, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:children)
    assert assigns(:children).any?(&:deleted), 'Privileged user cannot see deleted answers'
  end

  test 'show redirects parented to parent post' do
    get :show, params: { id: posts(:answer_one).id }
    assert_response 302
    assert_redirected_to post_path(posts(:answer_one).parent_id)
  end

  test 'unprivileged user cannot see post in high trust level category' do
    sign_in users(:standard_user)
    get :show, params: { id: posts(:high_trust).id }
    assert_response 404
  end
end
