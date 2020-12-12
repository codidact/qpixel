require 'test_helper'

class ModWarningControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should require authentication to access pages' do
    sign_out :user
    [:log, :new].each do |path|
      get path, params: { user_id: users(:standard_user).id }
      assert_response(404)
    end
  end

  test 'should require moderator status to access pages' do
    sign_in users(:standard_user)
    [:log, :new].each do |path|
      get path, params: { user_id: users(:standard_user).id }
      assert_response(404)
    end
  end

  test 'suspended user should redirect to current warning page' do
    sign_in users(:standard_user)
    mod_warnings(:first_warning).update(active: true)

    current_controller = @controller
    @controller = CategoriesController.new
    get :homepage
    @controller = current_controller

    assert_redirected_to '/warning'
    mod_warnings(:first_warning).update(active: false)
  end

  test 'warned user should be able to accept warning' do
    sign_in users(:standard_user)
    @warning = mod_warnings(:first_warning)
    @warning.update(active: true)
    post :approve, params: { approve_checkbox: true }
    @warning.reload
    assert_not @warning.active
  end

  test 'suspended user should not be able to accept pending suspension' do
    sign_in users(:standard_user)
    @warning = mod_warnings(:third_warning)
    @warning.update(active: true)
    post :approve, params: { approve_checkbox: true }
    @warning.reload
    assert @warning.active
  end

  test 'suspended user should be able to accept outdated suspension' do
    sign_in users(:standard_user)
    @warning = mod_warnings(:second_warning)
    @warning.update(active: true)
    post :approve, params: { approve_checkbox: true }
    @warning.reload
    assert_not @warning.active
  end
end
