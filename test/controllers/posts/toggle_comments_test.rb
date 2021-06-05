require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can toggle comments' do
    sign_in users(:moderator)
    post :toggle_comments, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
    assert assigns(:post).comments_disabled
  end

  test 'toggle comments requires authentication' do
    post :toggle_comments, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'regular users cannot toggle comments' do
    sign_in users(:standard_user)
    post :toggle_comments, params: { id: posts(:question_one).id }
    assert_response 404
    assert_not_nil assigns(:post)
    assert_not assigns(:post).comments_disabled
  end

  test 'specifying delete all results in comments being deleted' do
    sign_in users(:moderator)
    post :toggle_comments, params: { id: posts(:question_one).id, delete_all_comments: true }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
    assert assigns(:post).comments_disabled
    assert assigns(:post).comments.all?(&:deleted?)
  end
end
