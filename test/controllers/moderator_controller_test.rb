require 'test_helper'

class ModeratorControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index' do
    sign_in users(:moderator)
    get :index
    assert_response(200)
  end

  test 'should require authentication to access pages' do
    sign_out :user
    [:index, :recently_deleted_posts].each do |path|
      get path
      assert_response(404)
    end
  end

  test 'should require moderator status to access pages' do
    sign_in users(:standard_user)
    [:index, :recently_deleted_posts].each do |path|
      get path
      assert_response(404)
    end
  end

  test 'should get recent comments page' do
    sign_in users(:moderator)
    get :recent_comments
    assert_response 200
    assert_not_nil assigns(:comments)
  end

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

  test 'can get promotions list' do
    sign_in users(:deleter)
    get :promotions
    assert_response 200
    assert_not_nil assigns(:promotions)
    assert_not_nil assigns(:posts)
  end

  test 'promotions list requires auth' do
    get :promotions
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'promotions list requires privileges' do
    sign_in users(:standard_user)
    get :promotions
    assert_response 404
  end

  test 'can remove a post from promotions' do
    RequestContext.redis.set 'network/promoted_posts',
                             JSON.dump({ posts(:question_one).id.to_s => 28.days.from_now.to_i })
    sign_in users(:deleter)
    delete :remove_promotion, params: { id: posts(:question_one).id }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_equal '{}', RequestContext.redis.get('network/promoted_posts')
  end

  test 'remove promotion requires auth' do
    delete :remove_promotion, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'remove promotion requires privileges' do
    sign_in users(:standard_user)
    delete :remove_promotion, params: { id: posts(:question_one).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal ['no_privilege'], JSON.parse(response.body)['errors']
  end

  test 'cannot remove unpromoted post' do
    sign_in users(:deleter)
    delete :remove_promotion, params: { id: posts(:question_two).id, format: :json }
    assert_response 404
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal ['not_promoted'], JSON.parse(response.body)['errors']
  end
end
