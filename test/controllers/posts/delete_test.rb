require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can delete post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:question_two)).count
    post :delete, params: { id: posts(:question_two).id }
    after_history = PostHistory.where(post: posts(:question_two)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_nil flash[:danger]
    assert_equal before_history + 1, after_history, 'PostHistory event not created on deletion'
  end

  test 'delete requires authentication' do
    post :delete, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot delete' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :delete, params: { id: posts(:question_one).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot delete a post with responses' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :delete, params: { id: posts(:question_one).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot delete a deleted post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:deleted)).count
    post :delete, params: { id: posts(:deleted).id }
    after_history = PostHistory.where(post: posts(:deleted)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot delete a locked post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:locked)).count
    post :delete, params: { id: posts(:locked).id }
    after_history = PostHistory.where(post: posts(:locked)).count
    assert_response 403
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'delete ensures all children are deleted' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post_id: posts(:bad_answers).children.map(&:id)).count
    post :delete, params: { id: posts(:bad_answers).id }
    after_history = PostHistory.where(post_id: posts(:bad_answers).children.map(&:id)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_nil flash[:danger]
    assert assigns(:post).children.all?(&:deleted), 'Answers not deleted with question'
    assert_equal before_history + posts(:bad_answers).children.count, after_history,
                 'Answer PostHistory events not created on question deletion'
  end
end
