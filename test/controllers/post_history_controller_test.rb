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

  test 'user without edit permissions cannot rollback post edit' do
    event = post_histories(:q1_edit)
    sign_in users(:standard_user2)

    assert_no_difference 'PostHistory.count' do
      post :rollback, params: { post_id: event.post_id, id: event.id }
      assert_not_nil flash[:danger]
    end

    # Verify no changes were made
    assert_not_equal event.before_state, assigns(:post).body_markdown
  end

  test 'privileged user can rollback post edit' do
    event = post_histories(:q1_edit)
    user = users(:editor)

    sign_in user

    # Rollback and check success, a new history event should be created
    assert_difference 'PostHistory.count' do
      post :rollback, params: { post_id: event.post_id, id: event.id }
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
end
