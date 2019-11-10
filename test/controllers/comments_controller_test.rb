require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "should create new comment" do
    sign_in users(:standard_user)
    post :create, params: { comment: { post_id: posts(:answer_two).id, content: "ABCDEF GHIJKL MNOPQR STUVWX YZ" } }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_response(302)
  end

  test "should update existing comment" do
    sign_in users(:standard_user)
    patch :update, params: { id: comments(:one).id, comment: { content: "ABCDEF GHIJKL MNOPQR STUVWX YZ" } }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_response(302)
  end

  test "should mark comment deleted" do
    sign_in users(:moderator)
    delete :destroy, params: { id: comments(:one).id }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_equal true, assigns(:comment).deleted
    assert_response(302)
  end

  test "should mark comment undeleted" do
    sign_in users(:moderator)
    delete :undelete, params: { id: comments(:one).id }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_equal false, assigns(:comment).deleted
    assert_response(302)
  end

  test "should mark question comment deleted" do
    sign_in users(:moderator)
    delete :destroy, params: { id: comments(:two).id }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_equal true, assigns(:comment).deleted
    assert_response(302)
  end

  test "should mark question comment undeleted" do
    sign_in users(:moderator)
    delete :undelete, params: { id: comments(:two).id }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_equal false, assigns(:comment).deleted
    assert_response(302)
  end

  test "should require authentication to post comment" do
    sign_out :user
    post :create
    assert_response(302)
  end

  test "should prevent users from editing comments from another" do
    sign_in users(:editor)  # Editor only applies to main posts, not comments.
    patch :update, params: { id: comments(:one).id }
    assert_response(401)
  end

  test "should prevent users from deleting comments from another" do
    sign_in users(:editor)
    delete :destroy, params: { id: comments(:one).id }
    assert_response(401)
  end

  test "should prevent users from undeleting comments from another" do
    sign_in users(:editor)
    delete :undelete, params: { id: comments(:one).id }
    assert_response(401)
  end

  test "should allow moderators to update comment" do
    sign_in users(:moderator)
    patch :update, params: { id: comments(:one).id, comment: { content: "ABCDEF GHIJKL MNOPQR STUVWX YZ" } }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_response(302)
  end

  test "should allow author to delete comment" do
    sign_in users(:standard_user)
    delete :destroy, params: { id: comments(:one).id }
    assert_not_nil assigns(:comment)
    assert_equal true, assigns(:comment).deleted
    assert_response(302)
  end

  test "should allow author to undelete comment" do
    sign_in users(:standard_user)
    delete :undelete, params: { id: comments(:one).id }
    assert_not_nil assigns(:comment)
    assert_equal false, assigns(:comment).deleted
    assert_response(302)
  end

  test "should create notification for mentioned user" do
    sign_in users(:standard_user)
    post :create, params: { comment: { post_id: posts(:question_one).id, content: "@admin ABCDEF GHIJKL MNOPQR STUVWX YZ" } }
    assert_not_nil assigns(:comment)
    assert_equal 1, users(:admin).notifications.count
    assert_response(302)
  end

  test "should prevent short comments" do
    sign_in users(:standard_user)
    post :create, params: { comment: { post_id: posts(:question_one).id, content: 'a' } }
    assert_not_nil assigns(:comment)
    assert_equal 'Comment failed to save.', flash[:error]
    assert_response(302)
  end

  test "should prevent long comments" do
    sign_in users(:standard_user)
    post :create, params: { comment: { post_id: posts(:answer_one).id, content: 'a'*501 } }
    assert_not_nil assigns(:comment)
    assert_equal 'Comment failed to save.', flash[:error]
    assert_response(302)
  end

  test "should prevent updating to short comment" do
    sign_in users(:standard_user)
    post :update, params: { id: comments(:one).id, comment: { post_id: posts(:answer_one).id, content: 'a' } }
    assert_not_nil assigns(:comment)
    assert_equal 'Comment failed to update.', flash[:error]
    assert_response(302)
  end

  test "should prevent updating to long comment" do
    sign_in users(:standard_user)
    post :update, params: { id: comments(:two).id, comment: { post_id: posts(:question_one).id, content: 'a'*501 } }
    assert_not_nil assigns(:comment)
    assert_equal 'Comment failed to update.', flash[:error]
    assert_response(302)
  end
end
