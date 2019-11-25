require 'test_helper'

class SiteSettingsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "should get index page" do
    sign_in users(:admin)
    get :index
    assert_not_nil assigns(:settings)
    assert_response(200)
  end

  test "should update existing setting" do
    sign_in users(:admin)
    post :update, params: { name: site_settings(:one).name, site_setting: { value: "ABCDEF" } }
    assert_response 200
    assert_not_nil assigns(:setting)
    assert_equal 'ABCDEF', JSON.parse(response.body)['setting']['value']
    assert_equal 'OK', JSON.parse(response.body)['status']
  end

  test "should require authentication to access index" do
    sign_out :user
    get :index
    assert_response(404)
  end

  test "should require admin status to access index" do
    sign_in users(:moderator)
    get :index
    assert_response(404)
  end
end
