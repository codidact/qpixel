require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'non-moderator users without flag_curate ability should not see deleted threads' do
    sign_in users(:editor)
    get :post, params: { post_id: posts(:question_one).id }, format: :json

    assert_response(:success)
    assert_valid_json_response
    threads = JSON.parse(response.body)
    assert_equal threads.any? { |t| t['deleted'] }, false
  end

  test 'moderators and users with flag_curate ability should see deleted threads' do
    sign_in users(:deleter)
    get :post, params: { post_id: posts(:question_one).id }, format: :json
    threads = JSON.parse(response.body)
    assert_equal threads.any? { |t| t['deleted'] }, true

    sign_in users(:moderator)
    get :post, params: { post_id: posts(:question_one).id }, format: :json
    threads = JSON.parse(response.body)
    assert_equal threads.any? { |t| t['deleted'] }, true
  end

  test 'users should see deleted threads on their own posts even if those threads are deleted' do
    sign_in users(:standard_user)
    get :post, params: { post_id: posts(:question_one).id }, format: :json

    assert_response(:success)
    assert_valid_json_response
    threads = JSON.parse(response.body)
    assert_equal threads.any? { |t| t['deleted'] }, true
  end

  test 'should get comment threads on post' do
    get :post, params: { post_id: posts(:question_one).id }
    assert_response(:success)
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:comment_threads)
  end
end
