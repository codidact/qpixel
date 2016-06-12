require 'test_helper'

class AnswersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get new answer page" do
    sign_in users(:standard_user)
    get :new, :id => questions(:one).id
    assert_response(200)
    assert_not_nil assigns(:answer)
    assert_not_nil assigns(:question)
  end
end
