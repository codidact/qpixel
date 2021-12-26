require 'test_helper'

class PostHistoryControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get post history page' do
    get :post, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:history)
    assert_not_nil assigns(:post)
  end

  test 'anon user can access public post history' do
    get :post, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:history)
    assert_not_nil assigns(:post)
  end

  test 'anon user cannot access deleted post history' do
    get :post, params: { id: posts(:deleted).id }
    assert_response 404
  end

  test 'privileged user can access deleted post history' do
    sign_in users(:deleter)
    get :post, params: { id: posts(:deleted).id }
    assert_response 200
    assert_not_nil assigns(:history)
    assert_not_nil assigns(:post)
  end
end
