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

  test "should create new answer" do
    sign_in users(:standard_user)
    post :create, :answer => { :body => "ABCDEF GHIJKL MNOPQR STUVWX YZ" }, :id => questions(:one).id
    assert_not_nil assigns(:answer)
    assert_not_nil assigns(:question)
    assert_response(302)
  end

  test "should get edit answer page" do
    sign_in users(:editor)
    get :edit, :id => answers(:one).id
    assert_response(200)
    assert_not_nil assigns(:answer)
  end

  test "should update existing answer" do
    sign_in users(:editor)
    patch :update, :answer => { :body => "ABCDEF GHIJKL MNOPQR STUVWX YZ" }, :id => answers(:one).id
    assert_not_nil assigns(:answer)
    assert_response(302)
  end

  test "should mark answer deleted" do
    sign_in users(:deleter)
    delete :destroy, :id => answers(:one).id
    assert_not_nil assigns(:answer)
    assert_equal assigns(:answer).is_deleted, true
    assert_not_nil assigns(:answer).deleted_at
    assert_response(302)
  end

  test "should mark answer undeleted" do
    sign_in users(:deleter)
    delete :undelete, :id => answers(:one).id
    assert_not_nil assigns(:answer)
    assert_equal assigns(:answer).is_deleted, false
    assert_not_nil assigns(:answer).deleted_at
    assert_response(302)
  end

  test "should require authentication to answer" do
    sign_out :user
    get :new, :id => questions(:one).id
    assert_response(302)
    post :create, :id => questions(:one).id
    assert_response(302)
  end

  test "should require edit privileges to edit" do
    sign_out :user
    get :edit, :id => answers(:one).id
    assert_response(302)
    patch :update, :id => answers(:one).id
    assert_response(302)

    sign_in users(:standard_user)
    get :edit, :id => answers(:one).id
    assert_response(401)
    patch :update, :id => answers(:one).id
    assert_response(401)
  end

  test "should require delete privileges to delete" do
    sign_out :user
    delete :destroy, :id => answers(:one).id
    assert_response(302)
    delete :undelete, :id => answers(:one).id
    assert_response(302)

    sign_in users(:standard_user)
    delete :destroy, :id => answers(:one).id
    assert_response(401)
    delete :undelete, :id => answers(:one).id
    assert_response(401)

    sign_in users(:editor)
    delete :destroy, :id => answers(:one).id
    assert_response(401)
    delete :undelete, :id => answers(:one).id
    assert_response(401)
  end
end
