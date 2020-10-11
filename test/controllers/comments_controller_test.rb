require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should create new comment' do
    sign_in users(:standard_user)
    post :create, params: { comment: { post_id: posts(:answer_two).id, content: 'ABCDEF GHIJKL MNOPQR STUVWX YZ' } }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_response(200)
  end

  test 'should update existing comment' do
    sign_in users(:standard_user)
    patch :update, params: { id: comments(:one).id, comment: { content: 'ABCDEF GHIJKL MNOPQR STUVWX YZ' } }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_response(200)
  end

  test 'should mark comment deleted' do
    sign_in users(:moderator)
    delete :destroy, params: { id: comments(:one).id }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_equal true, assigns(:comment).deleted
    assert_response(200)
  end

  test 'should mark comment undeleted' do
    sign_in users(:moderator)
    delete :undelete, params: { id: comments(:one).id }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_equal false, assigns(:comment).deleted
    assert_response(200)
  end

  test 'should mark question comment deleted' do
    sign_in users(:moderator)
    delete :destroy, params: { id: comments(:two).id }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_equal true, assigns(:comment).deleted
    assert_response(200)
  end

  test 'should mark question comment undeleted' do
    sign_in users(:moderator)
    delete :undelete, params: { id: comments(:two).id }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_equal false, assigns(:comment).deleted
    assert_response(200)
  end

  test 'should require authentication to post comment' do
    sign_out :user
    post :create
    assert_response(302)
  end

  test 'should prevent users from editing comments from another' do
    sign_in users(:editor) # Editor only applies to main posts, not comments.
    patch :update, params: { id: comments(:one).id }
    assert_response(403)
  end

  test 'should prevent users from deleting comments from another' do
    sign_in users(:editor)
    delete :destroy, params: { id: comments(:one).id }
    assert_response(403)
  end

  test 'should prevent users from undeleting comments from another' do
    sign_in users(:editor)
    delete :undelete, params: { id: comments(:one).id }
    assert_response(403)
  end

  test 'should allow moderators to update comment' do
    sign_in users(:moderator)
    patch :update, params: { id: comments(:one).id, comment: { content: 'ABCDEF GHIJKL MNOPQR STUVWX YZ' } }
    assert_not_nil assigns(:comment)
    assert_not_nil assigns(:comment).post
    assert_response(200)
  end

  test 'should allow author to delete comment' do
    sign_in users(:standard_user)
    delete :destroy, params: { id: comments(:one).id }
    assert_not_nil assigns(:comment)
    assert_equal true, assigns(:comment).deleted
    assert_response(200)
  end

  test 'should allow author to undelete comment' do
    sign_in users(:standard_user)
    delete :undelete, params: { id: comments(:one).id }
    assert_not_nil assigns(:comment)
    assert_equal false, assigns(:comment).deleted
    assert_response(200)
  end

  test 'should create notification for mentioned user' do
    sign_in users(:standard_user)
    post :create, params: { comment: { post_id: posts(:question_one).id, content: '@admin ABCDEF GHIJKL MNOPQR STUVWX YZ' } }
    assert_not_nil assigns(:comment)
    assert_equal 1, users(:admin).notifications.count
    assert_response(200)
  end

  test 'should prevent short comments' do
    sign_in users(:standard_user)
    post :create, params: { comment: { post_id: posts(:question_one).id, content: 'a' } }
    assert_not_nil assigns(:comment)
    assert_response(500)
  end

  test 'should prevent long comments' do
    sign_in users(:standard_user)
    post :create, params: { comment: { post_id: posts(:answer_one).id, content: 'a' * 501 } }
    assert_not_nil assigns(:comment)
    assert_response(500)
  end

  test 'should prevent updating to short comment' do
    sign_in users(:standard_user)
    post :update, params: { id: comments(:one).id, comment: { post_id: posts(:answer_one).id, content: 'a' } }
    assert_not_nil assigns(:comment)
    assert_response(500)
  end

  test 'should prevent updating to long comment' do
    sign_in users(:standard_user)
    post :update, params: { id: comments(:two).id, comment: { post_id: posts(:question_one).id, content: 'a' * 501 } }
    assert_not_nil assigns(:comment)
    assert_response(500)
  end

  test 'should get comment as HTML' do
    sign_in users(:standard_user)
    get :show, params: { id: comments(:one).id }
    assert_not_nil assigns(:comment)
    assert_response 200
  end

  test 'should get comment as JSON' do
    sign_in users(:standard_user)
    get :show, params: { id: comments(:one).id, format: 'json' }
    assert_not_nil assigns(:comment)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_response 200
  end

  test 'should get post comments as HTML' do
    get :post, params: { post_id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:comments)
  end

  test 'should get post comments as JSON' do
    get :post, params: { post_id: posts(:question_one).id, format: :json }
    assert_response 200
    assert_not_nil assigns(:comments)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert JSON.parse(response.body).all? { |comment| comment['deleted'] == false },
           'Unauthenticated comment request contains deleted comment'
  end

  test 'should get comments including deleted as admin' do
    sign_in users(:moderator)
    get :post, params: { post_id: posts(:question_one).id, format: :json }
    assert_response 200
    assert_not_nil assigns(:comments)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert JSON.parse(response.body).any? { |comment| comment['deleted'] == true },
           'Authenticated comment request contains no deleted comments'
  end
end
