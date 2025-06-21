require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should create new thread' do
    sign_in users(:editor)

    before_author_notifs = users(:standard_user).notifications.count
    before_uninvolved_notifs = users(:moderator).notifications.count

    try_create_thread(posts(:question_one), mentions: [users(:deleter), users(:moderator)])

    assert_response(:found)
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
    try_create_thread(posts(:question_one))

    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'should not create thread if comments are disabled on the target post' do
    sign_in users(:editor)

    try_create_thread(posts(:comments_disabled), format: :json)

    assert_response(:forbidden)
    assert_valid_json_response
    assert_equal 'Comments have been disabled on this post.', JSON.parse(response.body)['message']
  end

  test 'should not create thread if the target post is inaccessible' do
    sign_in users(:editor)
    try_create_thread(posts(:high_trust))
    assert_response(:not_found)
  end

  test 'should not create thread if the target post is deleted' do
    sign_in users(:editor)
    try_create_thread(posts(:deleted))
    assert_response(:not_found)
  end

  test 'non-moderator users without flag_curate ability should not see deleted threads' do
    sign_in users(:editor)
    get :post, params: { post_id: posts(:question_one).id }, format: :json

    assert_response(:success)
    assert_valid_json_response
    threads = JSON.parse(response.body)
    assert_equal threads.any? { |t| t['deleted'] }, false
  end

  test 'moderators and users with flag_curate ability should see deleted threads' do
    sign_in users(:deleter)
    get :post, params: { post_id: posts(:question_one).id }, format: :json
    threads = JSON.parse(response.body)
    assert_equal threads.any? { |t| t['deleted'] }, true

    sign_in users(:moderator)
    get :post, params: { post_id: posts(:question_one).id }, format: :json
    threads = JSON.parse(response.body)
    assert_equal threads.any? { |t| t['deleted'] }, true
  end

  test 'users should see deleted threads on their own posts even if those threads are deleted' do
    sign_in users(:standard_user)
    get :post, params: { post_id: posts(:question_one).id }, format: :json

    assert_response(:success)
    assert_valid_json_response
    threads = JSON.parse(response.body)
    assert_equal threads.any? { |t| t['deleted'] }, true
  end

  test 'should add comment to existing thread' do
    sign_in users(:editor)
    before_author_notifs = users(:standard_user).notifications.count
    before_follow_notifs = users(:deleter).notifications.count
    before_uninvolved_notifs = users(:moderator).notifications.count

    post :create, params: { id: comment_threads(:normal).id,
                            post_id: posts(:question_one).id,
                            content: "comment content @##{users(:deleter).id} @##{users(:moderator).id}" }

    assert_response(:found)
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
    post :create, params: { id: comment_threads(:normal).id,
                            post_id: posts(:question_one).id,
                            content: "comment content @##{users(:deleter).id} @##{users(:moderator).id}" }

    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'should not add comment if comments disabled' do
    sign_in users(:editor)

    post :create, params: { id: comment_threads(:comments_disabled).id,
                            post_id: posts(:comments_disabled).id,
                            content: "comment content @##{users(:deleter).id} @##{users(:moderator).id}" },
                  format: :json

    assert_response(:forbidden)
    assert_valid_json_response
    assert_equal 'Comments have been disabled on this post.', JSON.parse(response.body)['message']
  end

  test 'should not add comment on inaccessible post' do
    sign_in users(:editor)

    post :create, params: { id: comment_threads(:high_trust).id,
                            post_id: posts(:high_trust).id,
                            content: "comment content @##{users(:deleter).id} @##{users(:moderator).id}" }

    assert_response(:not_found)
  end

  test 'should edit comment' do
    sign_in users(:standard_user)
    post :update, params: { id: comments(:one).id, comment: { content: 'Edited comment content' } }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require auth to edit comment' do
    post :update, params: { id: comments(:one).id, comment: { content: 'Edited comment content' } }
    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'should allow moderator to edit comment' do
    sign_in users(:moderator)
    post :update, params: { id: comments(:one).id, comment: { content: 'Edited comment content' } }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should not allow other users to edit comment' do
    sign_in users(:editor)
    post :update, params: { id: comments(:one).id, comment: { content: 'Edited comment content' } }
    assert_response(:forbidden)
  end

  test 'should delete comment' do
    sign_in users(:standard_user)
    delete :destroy, params: { id: comments(:one).id }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require auth to delete comment' do
    delete :destroy, params: { id: comments(:one).id }
    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'should allow moderator to delete comment' do
    sign_in users(:moderator)
    delete :destroy, params: { id: comments(:one).id }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should not allow other users to delete comment' do
    sign_in users(:editor)
    delete :destroy, params: { id: comments(:one).id }
    assert_response(:forbidden)
  end

  test 'should restore comment' do
    sign_in users(:standard_user)
    patch :undelete, params: { id: comments(:one).id }
    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require auth to restore comment' do
    patch :undelete, params: { id: comments(:one).id }
    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'should allow moderator to restore comment' do
    sign_in users(:moderator)
    patch :undelete, params: { id: comments(:one).id }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should not allow other users to restore comment' do
    sign_in users(:editor)
    patch :undelete, params: { id: comments(:one).id }
    assert_response(:forbidden)
  end

  test 'should get comment' do
    get :show, params: { id: comments(:one).id }
    assert_response(:success)
    assert_not_nil assigns(:comment)
  end

  test 'should get thread' do
    get :thread, params: { id: comment_threads(:normal).id }
    assert_response(:success)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should require auth to access high trust thread' do
    get :thread, params: { id: comment_threads(:high_trust).id }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should require privileges to access high trust thread' do
    sign_in users(:deleter)
    get :thread, params: { id: comment_threads(:high_trust).id }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should access thread on own deleted post' do
    sign_in users(:closer)
    get :thread, params: { id: comment_threads(:on_deleted_post).id }
    assert_response(:success)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should get thread followers' do
    sign_in users(:admin)
    get :thread_followers, params: { id: comment_threads(:normal).id }
    assert_response(:success)
    assert_not_nil assigns(:comment_thread)
    assert_not_nil assigns(:followers)
  end

  test 'should require auth to get thread followers' do
    get :thread_followers, params: { id: comment_threads(:normal).id }
    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'should require moderator to get thread followers' do
    sign_in users(:standard_user)
    get :thread_followers, params: { id: comment_threads(:normal).id }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should rename thread' do
    sign_in users(:deleter)
    post :thread_rename, params: { id: comment_threads(:normal).id, title: 'new thread title' }
    assert_response(:found)
    assert_not_nil assigns(:comment_thread)
    assert_redirected_to comment_thread_path(assigns(:comment_thread))
    assert_equal 'new thread title', assigns(:comment_thread).title
  end

  test 'should prevent non-moderator renaming locked thread' do
    sign_in users(:deleter)
    before_title = comment_threads(:locked).title
    post :thread_rename, params: { id: comment_threads(:locked).id, title: 'new thread title' }
    assert_response(:found)
    assert_not_nil assigns(:comment_thread)
    assert_redirected_to comment_thread_path(assigns(:comment_thread))
    assert_equal before_title, assigns(:comment_thread).title
  end

  test 'should lock thread' do
    sign_in users(:deleter)
    post :thread_restrict, params: { id: comment_threads(:normal).id, type: 'lock' }
    assert_response(:found)
    assert_not_nil assigns(:comment_thread)
    assert_redirected_to comment_thread_path(assigns(:comment_thread))
    assert_equal true, assigns(:comment_thread).locked
  end

  test 'should require privilege to lock thread' do
    sign_in users(:standard_user)
    post :thread_restrict, params: { id: comment_threads(:normal).id, type: 'lock' }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should delete thread' do
    sign_in users(:deleter)
    post :thread_restrict, params: { id: comment_threads(:normal).id, type: 'delete' }
    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require privilege to delete thread' do
    sign_in users(:standard_user)
    post :thread_restrict, params: { id: comment_threads(:normal).id, type: 'delete' }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should archive thread' do
    sign_in users(:deleter)
    post :thread_restrict, params: { id: comment_threads(:normal).id, type: 'archive' }
    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require privilege to archive thread' do
    sign_in users(:standard_user)
    post :thread_restrict, params: { id: comment_threads(:normal).id, type: 'archive' }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should follow thread' do
    sign_in users(:standard_user)
    post :thread_restrict, params: { id: comment_threads(:normal).id, type: 'follow' }
    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should unlock thread' do
    sign_in users(:deleter)
    post :thread_unrestrict, params: { id: comment_threads(:locked).id, type: 'lock' }
    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require privilege to unlock thread' do
    sign_in users(:standard_user)
    post :thread_unrestrict, params: { id: comment_threads(:locked).id, type: 'lock' }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should undelete thread' do
    sign_in users(:moderator)
    post :thread_unrestrict, params: { id: comment_threads(:deleted).id, type: 'delete' }
    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require privilege to undelete thread' do
    sign_in users(:standard_user)
    post :thread_unrestrict, params: { id: comment_threads(:deleted).id, type: 'delete' }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should unarchive thread' do
    sign_in users(:deleter)
    post :thread_unrestrict, params: { id: comment_threads(:archived).id, type: 'archive' }
    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require privilege to unarchive thread' do
    sign_in users(:standard_user)
    post :thread_unrestrict, params: { id: comment_threads(:archived).id, type: 'archive' }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should unfollow thread' do
    sign_in users(:standard_user)
    post :thread_unrestrict, params: { id: comment_threads(:normal).id, type: 'follow' }
    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should get comment threads on post' do
    get :post, params: { post_id: posts(:question_one).id }
    assert_response(:success)
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:comment_threads)
  end

  test 'should get pingable users on thread' do
    sign_in users(:standard_user)
    get :pingable, params: { id: -1, post: posts(:question_one).id }
    assert_response(:success)
    assert_valid_json_response
  end

  private

  # @param post [Post]
  # @param mentions [Array<User>]
  def try_create_thread(post, mentions: [], format: :html)
    body_parts = ['sample comment content'] + mentions.map { |u| "@##{u.id}" }

    post(:create_thread, params: { post_id: post.id,
                                   title: 'sample thread title',
                                   body: body_parts.join(' ') },
                         format: format)
  end
end
