require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should correctly create threads' do
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

  test 'should correctly default thread title if not provided' do
    sign_in users(:editor)

    {
      'a' * 99 => ->(thread) { thread.comments.first.content },
      'a' * 200 => ->(thread) { "#{thread.comments.first.content[0..100]}..." }
    }.each do |content, matcher|
      try_create_thread(posts(:question_one), content: content, mentions: [], title: '')

      assert_response(:found)
      thread = assigns(:comment_thread)
      assert_equal thread.title, matcher.call(thread)
    end
  end

  test 'should require auth to create thread' do
    try_create_thread(posts(:question_one))
    assert_redirected_to_sign_in
  end

  test 'should not create thread if comments are disabled on the target post' do
    sign_in users(:editor)
    try_create_thread(posts(:comments_disabled), format: :json)

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('Comments have been disabled on this post.')
  end

  test 'should not create thread if the target post is inaccessible' do
    sign_in users(:editor)
    try_create_thread(posts(:high_trust))
    assert_response(:not_found)
  end

  test 'should not create thread if the target post is deleted' do
    sign_in users(:editor)
    try_create_thread(posts(:deleted), format: :json)

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('Comments are disabled on deleted posts.')
  end

  test 'should not create thread if the target post is locked' do
    sign_in users(:editor)
    try_create_thread(posts(:locked), format: :json)

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('Comments are disabled on locked posts.')
  end

  test 'should not create thread if the target post does not allow comments for some reason' do
    sign_in users(:editor)

    post = posts(:question_one)

    post.stub(:comments_allowed?, false) do
      Post.stub(:find, post) do
        try_create_thread(post, format: :json)
        assert_response(:forbidden)
        assert_valid_json_response
        assert_json_response_message('You cannot comment on this post.')
      end
    end
  end

  test 'should correclty create comments in threads' do
    sign_in users(:editor)
    before_author_notifs = users(:standard_user).notifications.count
    before_follow_notifs = users(:deleter).notifications.count
    before_uninvolved_notifs = users(:moderator).notifications.count

    try_create_comment(comment_threads(:normal), mentions: [users(:deleter), users(:moderator)])

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

  test 'should require auth to create comments' do
    try_create_comment(comment_threads(:normal))
    assert_redirected_to_sign_in
  end

  test 'should not create comment if comments are disabled on the target post' do
    sign_in users(:editor)

    try_create_comment(comment_threads(:comments_disabled), format: :json)

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('Comments have been disabled on this post.')
  end

  test 'should not create comment if the target post is inaccessible' do
    sign_in users(:editor)
    try_create_comment(comment_threads(:high_trust))
    assert_response(:not_found)
  end
end
