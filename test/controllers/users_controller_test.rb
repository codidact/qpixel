require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get index" do
    get :index
    assert_not_nil assigns(:users)
    assert_response(200)
  end

  test "should get show user page" do
    get :show, :id => users(:standard_user).id
    assert_not_nil assigns(:user)
    assert_response(200)
  end
end
