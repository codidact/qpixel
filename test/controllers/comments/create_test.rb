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

  test 'should not create threads on posts of others without the unrestricted ability when rate-limited' do
    sign_in users(:basic_user)

    SiteSetting['RL_NewUserComments'] = 0

    post = posts(:question_one)

    try_create_thread(post)

    assert_not_nil flash[:danger]
    assert_redirected_to @controller.helpers.generic_share_link(post)
  end

  test 'should not create thread if the target post is inaccessible' do
    sign_in users(:editor)
    try_create_thread(posts(:high_trust))
    assert_response(:not_found)
  end

  test 'should not create thread if the target post does not allow comments for known reasons' do
    sign_in users(:editor)

    [:comments_disabled, :deleted, :locked].each do |name|
      post = posts(name)

      assert !post.comments_allowed?

      try_create_thread(post, format: :json)

      assert_response(:forbidden)
      assert_valid_json_response
      assert_json_response_message(@controller.helpers.comments_post_error_msg(post))
    end
  end

  test 'should return a catch-all response if the target post does not allow comments for an unknown reason' do
    sign_in users(:editor)

    post = posts(:question_one)

    post.stub(:comments_allowed?, false) do
      Post.stub(:find, post) do
        try_create_thread(post, format: :json)

        assert_response(:forbidden)
        assert_valid_json_response
        assert_json_response_message(@controller.helpers.comments_post_error_msg(post))
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

  test 'should correctly redirect depending on the inline parameter' do
    thread = comment_threads(:normal)
    editor = users(:editor)

    sign_in editor

    [false, true].each do |inline|
      try_create_comment(thread, inline: inline)

      assert_response(:found)

      if inline
        comment = Comment.by(editor).where(comment_thread: thread).last

        assert_redirected_to @controller.helpers.generic_share_link(thread.post,
                                                                    comment_id: comment.id,
                                                                    thread_id: thread.id)
      else
        assert_redirected_to comment_thread_path(thread)
      end
    end
  end

  test 'should require auth to create comments' do
    try_create_comment(comment_threads(:normal))
    assert_redirected_to_sign_in
  end

  test 'should not create comments on threads on posts of others without the unrestricted ability when rate-limited' do
    sign_in users(:basic_user)

    SiteSetting['RL_NewUserComments'] = 0

    thread = comment_threads(:normal)

    try_create_comment(thread)

    assert_not_nil flash[:danger]
    assert_redirected_to @controller.helpers.generic_share_link(thread.post)
  end

  test 'should not create comment if the target post is inaccessible' do
    sign_in users(:editor)
    try_create_comment(comment_threads(:high_trust))
    assert_response(:not_found)
  end

  test 'should not create comment if the target thread is readonly for a known reason' do
    sign_in users(:editor)

    [:locked, :deleted, :archived].each do |name|
      thread = comment_threads(name)

      assert thread.read_only?

      try_create_comment(thread, format: :json)

      assert_response(:forbidden)
      assert_valid_json_response
      assert_json_response_message(@controller.helpers.comments_thread_error_msg(thread))
    end
  end

  test 'should return a catch-all response if the target thread is readonly for an unknown reason' do
    sign_in users(:editor)

    thread = comment_threads(:normal)

    thread.stub(:read_only?, true) do
      CommentThread.stub(:find, thread) do
        try_create_comment(thread, format: :json)

        assert_response(:forbidden)
        assert_valid_json_response
        assert_json_response_message(@controller.helpers.comments_thread_error_msg(thread))
      end
    end
  end
end
