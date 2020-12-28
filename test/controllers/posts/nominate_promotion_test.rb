require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can nominate for promotion' do
    sign_in users(:deleter)
    post :nominate_promotion, params: { id: posts(:question_one).id }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'cannot nominate locked post' do
    sign_in users(:deleter)
    post :nominate_promotion, params: { id: posts(:locked).id, format: :json }
    assert_response 403
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'nominate requires authentication' do
    post :nominate_promotion, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'unprivileged user cannot nominate' do
    sign_in users(:standard_user)
    post :nominate_promotion, params: { id: posts(:question_one).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal ['no_privilege'], JSON.parse(response.body)['errors']
  end

  test 'cannot nominate second-level post' do
    sign_in users(:deleter)
    post :nominate_promotion, params: { id: posts(:answer_one).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal ['unavailable_for_type'], JSON.parse(response.body)['errors']
  end
end
