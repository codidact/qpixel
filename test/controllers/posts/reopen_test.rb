require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can reopen question' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:closed)).count
    post :reopen, params: { id: posts(:closed).id }
    after_history = PostHistory.where(post: posts(:closed)).count
    assert_response 302
    assert_redirected_to post_path(posts(:closed))
    assert_nil flash[:danger]
    assert_equal before_history + 1, after_history, 'PostHistory event not created on reopen'
  end

  test 'reopen requires authentication' do
    post :reopen, params: { id: posts(:closed).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot reopen' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:closed)).count
    post :reopen, params: { id: posts(:closed).id }
    after_history = PostHistory.where(post: posts(:closed)).count
    assert_response 302
    assert_redirected_to post_path(posts(:closed))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on reopen'
  end

  test 'cannot reopen an open post' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :reopen, params: { id: posts(:question_one).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on reopen'
  end

  test 'cannot reopen a locked post' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:locked)).count
    post :reopen, params: { id: posts(:locked).id }
    after_history = PostHistory.where(post: posts(:locked)).count
    assert_response 403
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on reopen'
  end
end
