require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can restore post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:deleted)).count
    post :restore, params: { id: posts(:deleted).id }
    after_history = PostHistory.where(post: posts(:deleted)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_nil flash[:danger]
    assert_equal before_history + 1, after_history, 'PostHistory event not created on deletion'
  end

  test 'restore requires authentication' do
    post :restore, params: { id: posts(:deleted).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot restore' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:deleted)).count
    post :restore, params: { id: posts(:deleted).id }
    after_history = PostHistory.where(post: posts(:deleted)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot restore a post deleted by a moderator' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:deleted_mod)).count
    post :restore, params: { id: posts(:deleted_mod).id }
    after_history = PostHistory.where(post: posts(:deleted_mod)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot restore a restored post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :restore, params: { id: posts(:question_one).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot restore a locked post' do
    sign_in users(:deleter)
    before_history = PostHistory.where(post: posts(:locked)).count
    post :restore, params: { id: posts(:locked).id }
    after_history = PostHistory.where(post: posts(:locked)).count
    assert_response 403
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'restore brings back all answers deleted after question' do
    sign_in users(:deleter)
    deleted_at = posts(:deleted).deleted_at
    children = posts(:deleted).children.where('deleted_at >= ?', deleted_at)
    children_count = children.count
    before_history = PostHistory.where(post_id: children.where('deleted_at >= ?', deleted_at)).count
    post :restore, params: { id: posts(:deleted).id }
    after_history = PostHistory.where(post_id: children.where('deleted_at >= ?', deleted_at)).count
    assert_response 302
    assert_redirected_to post_path(assigns(:post))
    assert_nil flash[:danger]
    assert_equal before_history + children_count, after_history,
                 'Answer PostHistory events not created on question restore'
  end
end
