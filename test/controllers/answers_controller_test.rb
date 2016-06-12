require 'test_helper'

class AnswersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get new answer page" do
    get :new, :id => questions(:one).id
    assert_equal assigns(:answer), Answer.new
    assert_not_nil assigns(:question)
    assert_response(200)
  end
end
