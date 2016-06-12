require 'test_helper'

class AnswersControllerTest < ActionController::TestCase
  test "should get new answer page" do
    get :new, :id => questions(:one).id
    assert_not_nil assigns(:answer)
    assert_not_nil assigns(:question)
    assert_response(200)
  end
end
