require 'test_helper'

class PostHistoryControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get post history page' do
    get :post, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:history)
    assert_not_nil assigns(:post)
  end

  test 'anon user can access public post history' do
    get :post, params: { id: posts(:question_one).id }
    assert_response 200
    assert_not_nil assigns(:history)
    assert_not_nil assigns(:post)
  end

  test 'anon user cannot access deleted post history' do
    get :post, params: { id: posts(:deleted).id }
    assert_response 404
  end

  test 'privileged user can access deleted post history' do
    sign_in users(:deleter)
    get :post, params: { id: posts(:deleted).id }
    assert_response 200
    assert_not_nil assigns(:history)
    assert_not_nil assigns(:post)
  end

  # -----------------------------------------------------------------------------------------------
  # Rollbacks
  # -----------------------------------------------------------------------------------------------

  test 'user without edit permissions cannot undo post edit' do
    event = post_histories(:q1_edit)
    sign_in users(:standard_user2)

    assert_no_difference 'PostHistory.count' do
      post :undo, params: { post_id: event.post_id, id: event.id }
      assert_not_nil flash[:danger]
    end

    # Verify no changes were made
    assert_not_equal event.before_state, assigns(:post).body_markdown
  end

  test 'privileged user can undo post edit' do
    event = post_histories(:q1_edit)
    user = users(:editor)

    sign_in user

    # Rollback and check success, a new history event should be created
    assert_difference 'PostHistory.count' do
      post :undo, params: { post_id: event.post_id, id: event.id }
      assert_not_nil flash[:success]
    end

    # New edit event should have been made, which should be the reverse of our event
    new_event = PostHistory.last
    assert_equal 'post_edited', new_event.post_history_type.name
    assert_equal user.id, new_event.user_id
    assert_equal event.before_state, new_event.after_state
    assert_equal event.after_state, new_event.before_state
    assert_equal event.before_title, new_event.after_title
    assert_equal event.after_title, new_event.before_title
    # The following doesn't always hold for a rollback, but should hold for this particular event
    assert_equal event.before_tags.to_a.sort_by(&:id), new_event.after_tags.to_a.sort_by(&:id)
    assert_equal event.after_tags.to_a.sort_by(&:id), new_event.before_tags.to_a.sort_by(&:id)

    # Verify that the post was restored
    post = assigns(:post)
    assert_equal event.before_state, post.body_markdown
    assert_equal event.before_title, post.title

    # Verify that all the tags that were there before are now again present on the post
    assert_equal event.before_tags.to_a.sort_by(&:id), (post.tags & event.before_tags).sort_by(&:id)
  end

  test 'unprivileged user cannot rollback to state' do
    event = posts(:question_one).post_histories.first
    user = users(:standard_user2)

    sign_in user
    assert_no_difference 'PostHistory.count' do
      post :rollback_to, params: { post_id: event.post_id, id: event.id }
      assert_not_nil flash[:danger]
    end

    # Assert no changes were made
    assert_not_equal event.before_state, assigns(:post).body_markdown
  end

  test 'privileged user can rollback to initial state if no hiding is involved' do
    event = posts(:question_one).post_histories
                                .where(post_history_type: PostHistoryType.find_by(name: 'initial_revision'))
                                .first
    user = users(:moderator)

    sign_in user
    assert_difference 'PostHistory.count' do
      post :rollback_to, params: { post_id: event.post_id, id: event.id, edit_comment: 'Suffs' }
      assert_not_nil flash[:success]
    end

    post = Post.find(assigns(:post).id)

    # Assert post was rolled back to state of initial
    assert_equal event.after_title, post.title
    assert_equal event.after_state, post.body_markdown
    assert_equal event.after_tags.ids.sort, post.tags.ids.sort
  end
end
