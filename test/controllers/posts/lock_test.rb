require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can lock post' do
    sign_in users(:deleter)
    post :lock, params: { id: posts(:question_one).id, format: :json }

    assert_response(:success)
    assert_not_nil assigns(:post)
    assert assigns(:post).locked_until <= 7.days.from_now
    assert assigns(:post).locked_until >= 7.days.from_now - 1.minute
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'lock requires authentication' do
    post :lock, params: { id: posts(:question_one).id }
    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot lock' do
    sign_in users(:standard_user)
    post :lock, params: { id: posts(:question_one).id, format: :json }

    assert_response(:not_found)
    assert_valid_json_response
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot lock locked post' do
    sign_in users(:deleter)
    post :lock, params: { id: posts(:locked).id, format: :json }

    assert_response(:not_found)
    assert_valid_json_response
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot lock longer than 30 days' do
    sign_in users(:deleter)
    post :lock, params: { id: posts(:question_one).id, length: 60, format: :json }

    assert_response(:success)
    assert_not_nil assigns(:post)
    assert assigns(:post).locked_until <= 30.days.from_now
    assert assigns(:post).locked_until >= 30.days.from_now - 1.minute
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'moderator can lock longer than 30 days' do
    sign_in users(:moderator)
    post :lock, params: { id: posts(:question_one).id, length: 60, format: :json }

    assert_response(:success)
    assert_not_nil assigns(:post)
    assert assigns(:post).locked_until <= 60.days.from_now
    assert assigns(:post).locked_until >= 60.days.from_now - 1.minute
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'moderator can lock indefinitely' do
    sign_in users(:moderator)
    post :lock, params: { id: posts(:question_one).id, format: :json }

    assert_response(:success)
    assert_not_nil assigns(:post)
    assert_nil assigns(:post).locked_until
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'Locks on posts expire' do
    sign_in users(:moderator)
    post :lock, params: { id: posts(:question_one).id, length: 1, format: :json }

    assert_response(:success)
    # Change the locked_until to have already passed
    assigns(:post).update(locked_until: 1.second.ago)
    assert_not assigns(:post).locked?
  end
end
