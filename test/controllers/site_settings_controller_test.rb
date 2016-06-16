require 'test_helper'

class SiteSettingsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get index page" do
    sign_in users(:admin)
    get :index
    assert_not_nil assigns(:settings)
    assert_response(200)
  end

  test "should get edit setting page" do
    sign_in users(:admin)
    get :edit, :id => site_settings(:one).id
    assert_not_nil assigns(:setting)
    assert_response(200)
  end

  test "should update existing setting" do
    sign_in users(:admin)
    patch :update, :id => site_settings(:one).id, :site_setting => { :value => "ABCDEF" }
    assert_not_nil assigns(:setting)
    assert_response(302)
  end

  test "should sanitize raw html strings" do
    sign_in users(:admin)
    patch :update, :id => site_settings(:sanitize).id, :site_setting => { :value => "<script>alert('omg xss2');</script>" }
    assert_not_nil assigns(:setting)
    assert_not assigns(:setting).value.include?("<script>")
    assert_response(302)
  end

  test "should require authentication to access index"
    sign_out :user
    get :index
    assert_response(401)
  end

  test "should require authentication to access edit page" do
    sign_out :user
    get :edit, :id => site_settings(:one).id
    assert_response(401)
  end

  test "should require authentication to update setting" do
    sign_out :user
    patch :update, :id => site_settings(:one).id
    assert_response(401)
  end

  test "should require admin status to access index"
    sign_in users(:moderator)
    get :index
    assert_response(401)
  end

  test "should require admin status to access edit page" do
    sign_in users(:moderator)
    get :edit, :id => site_settings(:one).id
    assert_response(401)
  end

  test "should require admin status to update setting" do
    sign_in users(:moderator)
    patch :update, :id => site_settings(:one).id
    assert_response(401)
  end
end
