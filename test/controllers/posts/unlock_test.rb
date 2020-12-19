require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can unlock post' do
    sign_in users(:deleter)
    posts(:locked).update(locked_until: 2.days.from_now)
    post :unlock, params: { id: posts(:locked).id, format: :json }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'unlock requires authentication' do
    post :unlock, params: { id: posts(:locked).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot unlock' do
    sign_in users(:standard_user)
    post :unlock, params: { id: posts(:locked).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot unlock unlocked post' do
    sign_in users(:deleter)
    post :unlock, params: { id: posts(:question_one).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'cannot unlock post locked by moderator' do
    sign_in users(:deleter)
    posts(:locked_mod).update(locked_until: 2.days.from_now)
    post :unlock, params: { id: posts(:locked_mod).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
    assert_equal ['locked_by_mod'], JSON.parse(response.body)['errors']
  end
end
