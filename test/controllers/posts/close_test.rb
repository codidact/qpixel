require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can close question' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :close, params: { id: posts(:question_one).id, reason_id: close_reasons(:not_good).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 200
    assert_not_nil assigns(:post)
    assert_equal before_history + 1, after_history, 'PostHistory event not created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'user can close own question' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :close, params: { id: posts(:question_one).id, reason_id: close_reasons(:not_good).id }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 200
    assert_not_nil assigns(:post)
    assert_equal before_history + 1, after_history, 'PostHistory event not created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'close requires authentication' do
    post :close, params: { id: posts(:question_one).id, reason_id: close_reasons(:not_good).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot close' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:question_two)).count
    post :close, params: { id: posts(:question_two).id, reason_id: close_reasons(:not_good).id }
    after_history = PostHistory.where(post: posts(:question_two)).count
    assert_response 403
    assert_not_nil assigns(:post)
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot close a closed post' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:closed)).count
    post :close, params: { id: posts(:closed).id, reason_id: close_reasons(:not_good).id }
    after_history = PostHistory.where(post: posts(:closed)).count
    assert_response 400
    assert_not_nil assigns(:post)
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'close rejects nonexistent close reason' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :close, params: { id: posts(:question_one).id, reason_id: -999 }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 404
    assert_not_nil assigns(:post)
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'close ensures other post exists if reason requires it' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    post :close, params: { id: posts(:question_one).id, reason_id: close_reasons(:duplicate) }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 400
    assert_not_nil assigns(:post)
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on closure'
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot close a locked post' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:locked)).count
    post :close, params: { id: posts(:locked).id, reason_id: close_reasons(:not_good).id }
    after_history = PostHistory.where(post: posts(:locked)).count
    assert_response 403
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on close'
  end
end
