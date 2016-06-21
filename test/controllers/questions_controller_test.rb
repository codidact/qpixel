require 'test_helper'

class QuestionsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get index" do
    get :index
    assert_not_nil assigns(:questions)
    assert_response(200)
  end

  test "should get show question page" do
    get :show, :id => questions(:one).id
    assert_not_nil assigns(:question)
    assert_not_nil assigns(:upvotes)
    assert_not_nil assigns(:downvotes)
    assert_response(200)
  end

  test "should get show question page with deleted question" do
    sign_in users(:deleter)
    get :show, :id => questions(:deleted).id
    assert_not_nil assigns(:question)
    assert_not_nil assigns(:upvotes)
    assert_not_nil assigns(:downvotes)
    assert_response(200)
  end

  test "should get tagged page" do
    get :tagged, :tag => "ABCDEF"
    assert_not_nil assigns(:questions)
    assert_response(200)
  end

  test "should get new question page" do
    sign_in users(:standard_user)
    get :new
    assert_not_nil assigns(:question)
    assert_response(200)
  end

  test "should create new question" do
    sign_in users(:standard_user)
    post :create, :question => { :title => "ABCDEF GHIJKL MNOPQR", :body => "ABCDEF GHIJKL MNOPQR STUVWX YZ", :tags => "ABCDEF GHIJKL" }
    assert_not_nil assigns(:question)
    assert_equal 0, assigns(:question).score
    assert_equal ["ABCDEF", "GHIJKL"], assigns(:question).tags
    assert_response(302)
  end

  test "should get edit question page" do
    sign_in users(:editor)
    get :edit, :id => questions(:one).id
    assert_not_nil assigns(:question)
    assert_response(200)
  end

  test "should update existing question" do
    sign_in users(:editor)
    patch :update, :id => questions(:one).id, :question => { :title => "ABCDEF GHIJKL MNOPQR", :body => "ABCDEF GHIJKL MNOPQR STUVWX YZ", :tags => "MNOPQR STUVWX" }
    assert_not_nil assigns(:question)
    assert_equal ["MNOPQR", "STUVWX"], assigns(:question).tags
    assert_response(302)
  end

  test "should mark question deleted" do
    sign_in users(:deleter)
    delete :destroy, :id => questions(:one).id
    assert_not_nil assigns(:question)
    assert_equal true, assigns(:question).is_deleted
    assert_response(302)
  end

  test "should mark question undeleted" do
    sign_in users(:deleter)
    delete :undelete, :id => questions(:one).id
    assert_not_nil assigns(:question)
    assert_equal false, assigns(:question).is_deleted
    assert_response(302)
  end

  test "should require authentication to get new question page" do
    sign_out :user
    get :new
    assert_response(302)
  end

  test "should require authentication to create new question" do
    sign_out :user
    post :create
    assert_response(302)
  end

  test "should require authentication to get edit question page" do
    sign_out :user
    get :edit, :id => questions(:one).id
    assert_response(302)
  end

  test "should require authentication to update existing question" do
    sign_out :user
    patch :update, :id => questions(:one).id
    assert_response(302)
  end

  test "should require authentication to mark question deleted" do
    sign_out :user
    delete :destroy, :id => questions(:one).id
    assert_response(302)
  end

  test "should require authentication to undelete question" do
    sign_out :user
    delete :undelete, :id => questions(:one).id
    assert_response(302)
  end

  test "should require edit privileges to get edit page" do
    sign_in users(:standard_user)
    get :edit, :id => questions(:two).id
    assert_response(401)
  end

  test "should require edit privileges to update existing question" do
    sign_in users(:standard_user)
    patch :update, :id => questions(:two).id
    assert_response(401)
  end

  test "should require delete privileges to mark question deleted" do
    sign_in users(:editor)
    delete :destroy, :id => questions(:one).id
    assert_response(401)
  end

  test "should require delete privileges to undelete question" do
    sign_in users(:editor)
    delete :undelete, :id => questions(:one).id
    assert_response(401)
  end

  test "should require viewdeleted privileges to view deleted question" do
    sign_in users(:editor)
    get :show, :id => questions(:deleted).id
    assert_response(404)
  end

  test "should prevent questions having more than 5 tags" do
    sign_in users(:standard_user)
    post :create, :question => { :title => "ABCDEF GHIJKL MNOPQR", :body => "ABCDEF GHIJKL MNOPQR STUVWX YZ", :tags => "ABCDEF GHIJKL MNOPQR STUVWX YZ ABC" }
    assert_not_nil assigns(:question).errors
    assert_response(400)
  end

  test "should prevent questions having no tags" do
    sign_in users(:standard_user)
    post :create, :question => { :title => "ABCDEF GHIJKL MNOPQR", :body => "ABCDEF GHIJKL MNOPQR STUVWX YZ", :tags => "" }
    assert_not_nil assigns(:question).errors
    assert_response(400)
  end

  test "should prevent tags being too long" do
    sign_in users(:standard_user)
    post :create, :question => { :title => "ABCDEF GHIJKL MNOPQR", :body => "ABCDEF GHIJKL MNOPQR STUVWX YZ", :tags => "123456789012345678901" }
    assert_not_nil assigns(:question).errors
    assert_response(400)
  end

  test "should prevent body being whitespace" do
    sign_in users(:standard_user)
    post :create, :question => { :title => "ABCDEF GHIJKL MNOPQR", :body => " "*31, :tags => "ABCDEF" }
    assert_not_nil assigns(:question).errors
    assert_response(400)
  end

  test "should prevent title being whitespace" do
    sign_in users(:standard_user)
    post :create, :question => { :title => " "*16, :body => "ABCDEF GHIJKL MNOPQR STUVWX YZ", :tags => "123456789012345678901" }
    assert_not_nil assigns(:question).errors
    assert_response(400)
  end

  test "should close question" do
    sign_in users(:closer)
    patch :close, :id => questions(:one).id
    assert_not_nil assigns(:question)
    assert_equal true, assigns(:question).is_closed
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response(200)
  end

  test "should reopen question" do
    sign_in users(:closer)
    patch :close, :id => questions(:closed).id
    assert_not_nil assigns(:question)
    assert_equal false, assigns(:question).is_closed
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response(200)
  end

  test "should require authentication to close question" do
    sign_out :user
    patch :close, :id => questions(:one).id
    assert_response(302)
  end

  test "should require authentication to reopen question" do
    sign_out :user
    patch :reopen, :id => questions(:closed).id
    assert_response(302)
  end

  test "should require privileges to close question" do
    sign_in user(:standard_user)
    patch :close, :id => questions(:one).id
    assert_equal 'failed', JSON.parse(response.body)['status']
    assert_response(401)
  end

  test "should require privileges to reopen question" do
    sign_in user(:standard_user)
    patch :reopen, :id => questions(:closed).id
    assert_equal 'failed', JSON.parse(response.body)['status']
    assert_response(401)
  end

  test "should prevent closed questions being closed" do
    sign_in users(:closer)
    patch :close, :id => questions(:closed).id
    assert_equal 'failed', JSON.parse(response.body)['status']
    assert_response(422)
  end

  test "should prevent open questions being reopened" do
    sign_in users(:closer)
    patch :reopen, :id => questions(:one).id
    assert_equal 'failed', JSON.parse(response.body)['status']
    assert_response(422)
  end
end
