require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should require authentication to access new' do
    get :new, params: { type: 'all' }
    assert_redirected_to_sign_in
  end

  test 'should require authentication to access index' do
    get :index
    assert_redirected_to_sign_in
  end

  test 'should get index when logged in' do
    sign_in users(:standard_user)
    get :index
    assert_response(:success)
    assert_not_nil assigns(:subscriptions)
    assert_not assigns(:subscriptions).empty?,
               '@subscriptions instance variable expected size > 0, got <= 0'
  end

  test 'should get new when logged in' do
    sign_in users(:standard_user)
    get :new, params: { type: 'all' }
    assert_response(:success)
    assert_not_nil assigns(:subscription)
  end

  test 'should create subscription' do
    sign_in users(:standard_user)
    post :create, params: { return_to: user_path(users(:moderator)),
                            subscription: { type: 'user', qualifier: users(:moderator).id, name: 'test', frequency: 7 } }
    assert_response(:found)
    assert_not_nil assigns(:subscription)
    assert_not_nil flash[:success]
    assert_redirected_to user_path(users(:moderator))
  end

  test 'should refuse to create tag subscription to nonexistent tag' do
    sign_in users(:standard_user)
    post :create, params: { subscription: { type: 'tag', qualifier: 'nope', name: 'test', frequency: 7 } }

    assert_response(:bad_request)
    assert_not_nil assigns(:subscription)
    assert assigns(:subscription).errors.any?, '@subscription failed to save without errors'
  end

  test 'should prevent users updating subscriptions belonging to others' do
    sign_in users(:editor)
    post :enable, params: { id: subscriptions(:all).id, enabled: true }

    assert_response(:forbidden)
    assert_not_nil assigns(:subscription)
    assert_valid_json_response
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'should prevent users removing subscriptions belonging to others' do
    sign_in users(:editor)
    post :destroy, params: { id: subscriptions(:all).id }

    assert_response(:forbidden)
    assert_not_nil assigns(:subscription)
    assert_valid_json_response
    assert_equal 'failed', JSON.parse(response.body)['status']
  end

  test 'should allow users to update their own subscriptions' do
    sign_in users(:standard_user)
    post :enable, params: { id: subscriptions(:all).id } # no enabled param should default to false

    assert_response(:success)
    assert_not_nil assigns(:subscription)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_equal false, assigns(:subscription).enabled
  end

  test 'should allow users to remove their own subscriptions' do
    sign_in users(:standard_user)
    post :destroy, params: { id: subscriptions(:all).id }

    assert_response(:success)
    assert_not_nil assigns(:subscription)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should allow admins to update others subscriptions' do
    sign_in users(:admin)
    post :enable, params: { id: subscriptions(:all).id } # no enabled param should default to false

    assert_response(:success)
    assert_not_nil assigns(:subscription)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_equal false, assigns(:subscription).enabled
  end

  test 'should allow admins to remove others subscriptions' do
    sign_in users(:admin)
    post :destroy, params: { id: subscriptions(:all).id }

    assert_response(:success)
    assert_not_nil assigns(:subscription)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end
end
