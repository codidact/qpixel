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

  test "should get mod tools page" do
    sign_in users(:moderator)
    get :mod, :id => users(:standard_user).id
    assert_not_nil assigns(:user)
    assert_response(200)
  end

  test "should require authentication to access mod tools" do
    sign_out :user
    get :mod, :id => users(:standard_user).id
    assert_nil assigns(:user)
    assert_response(401)
  end

  test "should require moderator status to access mod tools" do
    sign_in users(:standard_user)
    get :mod, :id => users(:standard_user).id
    assert_nil assigns(:user)
    assert_response(401)
  end
end
