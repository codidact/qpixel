require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can lock post' do
    sign_in users(:deleter)
    post :lock, params: { id: posts(:question_one).id, format: :json }
    assert_response 200
    assert_not_nil assigns(:post)
    assert assigns(:post).locked_until <= 7.days.from_now
    assert assigns(:post).locked_until >= 7.days.from_now - 1.minute
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'lock requires authentication' do
    post :lock, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot lock' do
    sign_in users(:standard_user)
    post :lock, params: { id: posts(:question_one).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot lock locked post' do
    sign_in users(:deleter)
    post :lock, params: { id: posts(:locked).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot lock longer than 30 days' do
    sign_in users(:deleter)
    post :lock, params: { id: posts(:question_one).id, length: 60, format: :json }
    assert_response 200
    assert_not_nil assigns(:post)
    assert assigns(:post).locked_until <= 30.days.from_now
    assert assigns(:post).locked_until >= 30.days.from_now - 1.minute
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'moderator can lock longer than 30 days' do
    sign_in users(:moderator)
    post :lock, params: { id: posts(:question_one).id, length: 60, format: :json }
    assert_response 200
    assert_not_nil assigns(:post)
    assert assigns(:post).locked_until <= 60.days.from_now
    assert assigns(:post).locked_until >= 60.days.from_now - 1.minute
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'moderator can lock indefinitely' do
    sign_in users(:moderator)
    post :lock, params: { id: posts(:question_one).id, format: :json }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_nil assigns(:post).locked_until
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end
end
