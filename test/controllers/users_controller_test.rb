require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get index" do
    get :index
    assert_not_nil assigns(:users)
    assert_response(200)
  end

  test "should get show user page" do
    sign_in users(:standard_user)
    get :show, :id => users(:standard_user).id
    assert_not_nil assigns(:user)
    assert_response(200)
  end

  test "should prevent anonymous users viewing profiles" do
    sign_out :user
    get :show, :id => users(:standard_user).id
    assert_nil assigns(:user)
    assert_response(200)
  end
end
