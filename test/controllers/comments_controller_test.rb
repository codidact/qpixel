require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should create new thread' do
    sign_in users(:editor)
    before_author_notifs = users(:standard_user).notifications.count
    before_uninvolved_notifs = users(:moderator).notifications.count
    post :create_thread, params: { post_id: posts(:question_one).id, title: 'sample thread title',
                                   body: "sample comment content @##{users(:deleter).id} @##{users(:moderator).id}" }
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:comment)&.id
    assert_not_nil assigns(:comment_thread)&.id
    assert_nil flash[:danger]
    assert_equal before_author_notifs + 1, users(:standard_user).notifications.count,
                 'Author notification not created when it should have been'
    assert_equal before_uninvolved_notifs, users(:moderator).notifications.count,
                 'Uninvolved notification created when it should not have been'
    assert assigns(:comment_thread).followed_by?(users(:editor)), 'Follower record not created for thread author'
  end

  test 'should require auth to create thread' do
    post :create_thread, params: { post_id: posts(:question_one).id, title: 'sample thread title',
                                   body: "sample comment content @##{users(:deleter).id} @##{users(:moderator).id}" }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should not create thread if comments disabled' do
    sign_in users(:editor)
    post :create_thread, params: { post_id: posts(:comments_disabled).id, title: 'sample thread title',
                                   body: "sample comment content @##{users(:deleter).id} @##{users(:moderator).id}" }
    assert_response 403
    assert_equal 'Comments have been disabled on this post.', JSON.parse(response.body)['message']
  end

  test 'should not create thread on inaccessible post' do
    sign_in users(:editor)
    post :create_thread, params: { post_id: posts(:high_trust).id, title: 'sample thread title',
                                   body: "sample comment content @##{users(:deleter).id} @##{users(:moderator).id}" }
    assert_response 404
  end

  test 'should add comment to existing thread' do
    sign_in users(:editor)
    before_author_notifs = users(:standard_user).notifications.count
    before_follow_notifs = users(:deleter).notifications.count
    before_uninvolved_notifs = users(:moderator).notifications.count
    post :create, params: { id: comment_threads(:normal).id, post_id: posts(:question_one).id,
                            content: "comment content @##{users(:deleter).id} @##{users(:moderator).id}" }
    assert_response 302
    assert_redirected_to comment_thread_path(assigns(:comment_thread))
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:comment_thread)
    assert_not_nil assigns(:comment)&.id
    assert_equal before_author_notifs + 1, users(:standard_user).notifications.count,
                 'Post author notification not created when it should have been'
    assert_equal before_follow_notifs + 1, users(:deleter).notifications.count,
                 'Thread follower notification not created when it should have been'
    assert_equal before_uninvolved_notifs, users(:moderator).notifications.count,
                 'Uninvolved notification created when it should not have been'
    assert assigns(:comment_thread).followed_by?(users(:editor)), 'Follower record not created for comment author'
  end

  test 'should require auth to add comment' do
    post :create, params: { id: comment_threads(:normal).id, post_id: posts(:question_one).id,
                            content: "comment content @##{users(:deleter).id} @##{users(:moderator).id}" }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should not add comment if comments disabled' do
    sign_in users(:editor)
    post :create, params: { id: comment_threads(:comments_disabled).id, post_id: posts(:comments_disabled).id,
                            content: "comment content @##{users(:deleter).id} @##{users(:moderator).id}" }
    assert_response 403
    assert_equal 'Comments have been disabled on this post.', JSON.parse(response.body)['message']
  end

  test 'should not add comment on inaccessible post' do
    sign_in users(:editor)
    post :create, params: { id: comment_threads(:high_trust).id, post_id: posts(:high_trust).id,
                            content: "comment content @##{users(:deleter).id} @##{users(:moderator).id}" }
    assert_response 404
  end

  test 'should edit comment' do
    sign_in users(:standard_user)
    post :update, params: { id: comments(:one).id, comment: { content: 'Edited comment content' } }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end
end
