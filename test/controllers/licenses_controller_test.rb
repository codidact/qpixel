require 'test_helper'

class LicensesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should require authentication to access license pages' do
    [:index, :new].each do |action|
      get action
      assert_response 302
      assert_redirected_to new_user_session_path
    end

    get :edit, params: { id: licenses(:cc_by_sa).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should require authentication to modify licenses' do
    post :create, params: { license: { name: 'Test', url: 'Test', default: false } }
    assert_response 302
    assert_redirected_to new_user_session_path

    patch :update, params: { id: licenses(:cc_by_sa).id, license: { name: 'Test', url: 'Test', default: false } }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should require admin to access license pages' do
    sign_in users(:standard_user)
    [:index, :new].each do |action|
      get action
      assert_response 404
    end

    get :edit, params: { id: licenses(:cc_by_sa).id }
    assert_response 404
  end

  test 'should require admin to modify licenses' do
    sign_in users(:standard_user)
    post :create, params: { license: { name: 'Test', url: 'Test', default: false } }
    assert_response 404

    patch :update, params: { id: licenses(:cc_by_sa).id, license: { name: 'Test', url: 'Test', default: false } }
    assert_response 404
  end

  test 'should allow admins to access index' do
    sign_in users(:admin)
    get :index
    assert_response 200
    assert_not_nil assigns(:licenses)
  end

  test 'should allow admins to access new' do
    sign_in users(:admin)
    get :new
    assert_response 200
    assert_not_nil assigns(:license)
  end

  test 'should allow admins to access edit' do
    sign_in users(:admin)
    get :edit, params: { id: licenses(:cc_by_sa).id }
    assert_response 200
    assert_not_nil assigns(:license)
  end

  test 'should allow admins to create new licenses' do
    sign_in users(:admin)
    post :create, params: { license: { name: 'Test', url: 'Test', default: false } }
    assert_response 302
    assert_redirected_to licenses_path
    assert_not_nil assigns(:license)
    assert_not_nil assigns(:license).id
    assert_equal 'Test', assigns(:license).name
  end

  test 'should allow admins to update existing license' do
    sign_in users(:admin)
    patch :update, params: { id: licenses(:cc_by_sa).id, license: { name: 'Test', url: 'Test', default: false } }
    assert_response 302
    assert_redirected_to licenses_path
    assert_not_nil assigns(:license)
    assert_equal 'Test', assigns(:license).name
  end

  test 'should allow admins to disable not-in-use license' do
    sign_in users(:admin)
    post :toggle, params: { id: licenses(:not_in_use).id }
    assert_response 302
    assert_redirected_to licenses_path
    assert_nil flash[:danger]
    assert_not_nil assigns(:license)
    assert_equal false, assigns(:license).enabled
  end

  test 'should prevent admins disabling in-use license' do
    sign_in users(:admin)
    post :toggle, params: { id: licenses(:cc_by_sa).id }
    assert_response 302
    assert_redirected_to licenses_path
    assert_not_nil assigns(:license)
    assert_not_nil flash[:danger]
    assert_equal true, assigns(:license).enabled
  end

  test 'should only allow one default license' do
    sign_in users(:admin)
    post :update, params: { id: licenses(:cc_by_nc_sa).id, license: { name: 'Test', url: 'Test', default: true } }
    assert_response 302
    assert_redirected_to licenses_path
    assert_not_nil assigns(:license)
    assert_equal true, assigns(:license).default
    assert_equal 1, License.where(default: true).count
  end
end
