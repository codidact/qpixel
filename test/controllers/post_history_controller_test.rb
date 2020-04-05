require 'test_helper'

class PostHistoryControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get post history page' do
    get :post, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:history)
    assert_not_nil assigns(:post)
  end
end
