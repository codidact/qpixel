require 'test_helper'

class SiteSettingsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index page' do
    sign_in users(:admin)
    get :index
    assert_not_nil assigns(:settings)
    assert_response(200)
  end

  test 'should update existing setting' do
    sign_in users(:admin)
    post :update, params: { community_id: RequestContext.community_id, name: site_settings(:one).name, site_setting: { value: 'ABCDEF' } }
    assert_response 200
    assert_not_nil assigns(:setting)
    assert_equal 'ABCDEF', JSON.parse(response.body)['setting']['value']
    assert_equal 'OK', JSON.parse(response.body)['status']
  end

  test 'should require authentication to access index' do
    sign_out :user
    get :index
    assert_response(404)
  end

  test 'should require admin status to access index' do
    sign_in users(:moderator)
    get :index
    assert_response(404)
  end

  test 'should require global admin to access global settings' do
    sign_in users(:global_admin)
    get :global
    assert_response 200
    assert_not_nil assigns(:settings)
  end

  test 'should deny global access to local admins' do
    sign_in users(:admin)
    get :global
    assert_response 404
  end

  test 'should allow global admin to update global setting' do
    sign_in users(:global_admin)
    post :update, params: { community_id: nil, name: site_settings(:one).name, site_setting: { value: 2 } }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'OK', JSON.parse(response.body)['status']
  end

  test 'should prevent local admin updating global setting' do
    sign_in users(:admin)
    post :update, params: { community_id: nil, name: site_settings(:one).name, site_setting: { value: 2 } }
    assert_response 404
  end

  test 'editing site setting should leave global alone' do
    sign_in users(:global_admin)
    pre_value = site_settings(:one).value
    pre_count = SiteSetting.unscoped.count
    post :update, params: { community_id: RequestContext.community_id, name: site_settings(:one).name, site_setting: { value: 'ABC' } }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'OK', JSON.parse(response.body)['status']
    assert_equal pre_value, site_settings(:one).value
    assert_equal pre_count + 1, SiteSetting.unscoped.count
  end
end
