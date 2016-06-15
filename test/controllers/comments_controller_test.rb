require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should create new comment" do
    sign_in users(:standard_user)
    post :create, :comment => { :post_id => answers(:two).id, :post_type => 'Answer', :content => "ABCDEF GHIJKL MNOPQR STUVWX YZ" }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_response(302)
  end

  test "should update existing comment" do
    sign_in users(:standard_user)
    patch :update, :id => comments(:one).id, :comment => { :content => "ABCDEF GHIJKL MNOPQR STUVWX YZ" }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_response(302)
  end

  test "should mark comment deleted" do
    sign_in users(:moderator)
    delete :destroy, :id => comments(:one).id
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_equal true, assigns(:comment).is_deleted
    assert_response(302)
  end

  test "should mark comment undeleted" do
    sign_in users(:moderator)
    delete :undelete, :id => comments(:one).id
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_equal false, assigns(:comment).is_deleted
    assert_response(302)
  end
end
