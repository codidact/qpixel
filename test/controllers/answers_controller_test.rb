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
    assert_equal true, assigns(:answer).is_deleted
    assert_not_nil assigns(:answer).deleted_at
    assert_response(302)
  end

  test "should mark answer undeleted" do
    sign_in users(:deleter)
    delete :undelete, :id => answers(:one).id
    assert_not_nil assigns(:answer)
    assert_equal false, assigns(:answer).is_deleted
    assert_not_nil assigns(:answer).deleted_at
    assert_response(302)
  end

  test "should require authentication to get new page" do
    sign_out :user
    get :new, :id => questions(:one).id
    assert_response(302)
  end

  test "should require authenitcation to create answer" do
    sign_out :user
    post :create, :id => questions(:one).id
    assert_response(302)
  end

  test "should require authentication to get edit page" do
    sign_out :user
    get :edit, :id => answers(:one).id
    assert_response(302)
  end

  test "should require authentication to update answer" do
    sign_out :user
    patch :update, :id => answers(:one).id
    assert_response(302)
  end

  test "should require user to have edit privileges to get edit page" do
    sign_in users(:standard_user)
    get :edit, :id => answers(:two).id
    assert_response(401)
  end

  test "should require user to have edit privileges to update answer" do
    sign_in users(:standard_user)
    patch :update, :id => answers(:two).id
    assert_response(401)
  end

  test "should require authentication to delete" do
    sign_out :user
    delete :destroy, :id => answers(:one).id
    assert_response(302)
  end

  test "should require authentication to undelete" do
    sign_out :user
    delete :undelete, :id => answers(:one).id
    assert_response(302)
  end

  test "should require above standard privileges to delete" do
    sign_in users(:standard_user)
    delete :destroy, :id => answers(:two).id
    assert_response(401)
  end

  test "should require above standard privileges to undelete" do
    sign_in users(:standard_user)
    delete :undelete, :id => answers(:two).id
    assert_response(401)
  end

  test "should require above edit privileges to delete" do
    sign_in users(:editor)
    delete :destroy, :id => answers(:one).id
    assert_response(401)
  end

  test "should require above edit privileges to undelete" do
    sign_in users(:editor)
    delete :undelete, :id => answers(:one).id
    assert_response(401)
  end

  test "should block short answers" do
    sign_in users(:standard_user)
    post :create, :answer => { :body => "ABCDEF" }, :id => questions(:one).id
    assert_response(422)
  end

  test "should block whitespace answers" do
    sign_in users(:standard_user)
    post :create, :answer => { :body => " "*31 }, :id => questions(:one).id
    assert_response(422)
  end

  test "should block long answers" do
    sign_in users(:standard_user)
    post :create, :answer => { :body => "A"*(3e4+1) }, :id => questions(:one).id
    assert_response(422)
  end
end
