require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should require authentication to access new' do
    get :new, params: { type: 'all' }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should require authentication to access index' do
    get :index
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should get index when logged in' do
    sign_in users(:standard_user)
    get :index
    assert_response 200
    assert_not_nil assigns(:subscriptions)
    assert_not assigns(:subscriptions).empty?,
               '@subscriptions instance variable expected size > 0, got <= 0'
  end

  test 'should get new when logged in' do
    sign_in users(:standard_user)
    get :new, params: { type: 'all' }
    assert_response 200
    assert_not_nil assigns(:phrasing)
    assert_not_nil assigns(:subscription)
  end

  test 'should create subscription' do
    sign_in users(:standard_user)
    post :create, params: { return_to: user_path(users(:moderator)),
                            subscription: { type: 'user', qualifier: users(:moderator).id, name: 'test', frequency: 7 } }
    assert_response 302
    assert_not_nil assigns(:subscription)
    assert_not_nil flash[:success]
    assert_redirected_to user_path(users(:moderator))
  end

  test 'should refuse to create tag subscription to nonexistent tag' do
    sign_in users(:standard_user)
    post :create, params: { subscription: { type: 'tag', qualifier: 'nope', name: 'test', frequency: 7 } }
    assert_response 500
    assert_not_nil assigns(:subscription)
    assert assigns(:subscription).errors.any?,
           '@subscription instance variable has no errors attached but failed to save'
  end

  test 'should prevent users updating subscriptions belonging to others' do
    sign_in users(:editor)
    post :enable, params: { id: subscriptions(:all).id, enabled: true }
    assert_response 403
    assert_not_nil assigns(:subscription)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'should prevent users removing subscriptions belonging to others' do
    sign_in users(:editor)
    post :destroy, params: { id: subscriptions(:all).id }
    assert_response 403
    assert_not_nil assigns(:subscription)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'should allow users to update their own subscriptions' do
    sign_in users(:standard_user)
    post :enable, params: { id: subscriptions(:all).id } # no enabled param should default to false
    assert_response 200
    assert_not_nil assigns(:subscription)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_equal false, assigns(:subscription).enabled
  end

  test 'should allow users to remove their own subscriptions' do
    sign_in users(:standard_user)
    post :destroy, params: { id: subscriptions(:all).id }
    assert_response 200
    assert_not_nil assigns(:subscription)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should allow admins to update others subscriptions' do
    sign_in users(:admin)
    post :enable, params: { id: subscriptions(:all).id } # no enabled param should default to false
    assert_response 200
    assert_not_nil assigns(:subscription)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_equal false, assigns(:subscription).enabled
  end

  test 'should allow admins to remove others subscriptions' do
    sign_in users(:admin)
    post :destroy, params: { id: subscriptions(:all).id }
    assert_response 200
    assert_not_nil assigns(:subscription)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end
end
