require 'test_helper'

class SiteSettingsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "should get index page" do
    sign_in users(:admin)
    get :index
    assert_not assigns(:settings).nil?
    assert_response(200)
  end

  test "should get edit setting page" do
    sign_in users(:admin)
    get :edit, params: { id: site_settings(:one).id }
    assert_not assigns(:setting).nil?
    assert_response(200)
  end

  test "should update existing setting" do
    sign_in users(:admin)
    patch :update, params: { id: site_settings(:one).id, site_setting: { value: "ABCDEF" } }
    assert_not assigns(:setting).nil?
    assert_response(302)
  end

  test "should sanitize raw html strings" do
    sign_in users(:admin)
    patch :update, params: { id: site_settings(:sanitize).id, site_setting: { value: "<script>alert('omg xss2');</script>" } }
    assert_not assigns(:setting).nil?
    assert_not assigns(:setting).value.include?("<script>")
    assert_response(302)
  end

  test "should require authentication to access index" do
    sign_out :user
    get :index
    assert_response(404)
  end

  test "should require authentication to access edit page" do
    sign_out :user
    get :edit, params: { id: site_settings(:one).id }
    assert_response(404)
  end

  test "should require authentication to update setting" do
    sign_out :user
    patch :update, params: { id: site_settings(:one).id }
    assert_response(404)
  end

  test "should require admin status to access index" do
    sign_in users(:moderator)
    get :index
    assert_response(404)
  end

  test "should require admin status to access edit page" do
    sign_in users(:moderator)
    get :edit, params: { id: site_settings(:one).id }
    assert_response(404)
  end

  test "should require admin status to update setting" do
    sign_in users(:moderator)
    patch :update, params: { id: site_settings(:one).id }
    assert_response(404)
  end
end
