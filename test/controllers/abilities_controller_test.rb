require 'test_helper'

class AbilitiesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index when logged in' do
    sign_in users(:standard_user)
    get :index
    assert_response 200
    assert_not_nil assigns(:abilities)
    assert_not_nil assigns(:user)
  end

  test 'should not get index when not logged in' do
    sign_out :user
    get :index
    assert_response 404
  end

  test 'should get index for other user when logged in' do
    sign_in users(:standard_user)
    get :index, params: { for: users(:closer).id }
    assert_response 200
    assert_not_nil assigns(:abilities)
    assert_not_nil assigns(:user)
  end

  test 'should get index for other user when not logged in' do
    sign_out :user
    get :index, params: { for: users(:closer).id }
    assert_response 200
    assert_not_nil assigns(:abilities)
    assert_not_nil assigns(:user)
  end

  test 'should get show when logged in' do
    sign_in users(:standard_user)
    get :show, params: { id: 'unrestricted' }
    assert_response 200
    assert_not_nil assigns(:ability)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:your_ability)
  end

  test 'should not get show when not logged in' do
    sign_out :user
    get :show, params: { id: 'unrestricted' }
    assert_response 404
  end

  test 'should get show for other user when logged in' do
    sign_in users(:standard_user)
    get :show, params: { id: 'unrestricted', for: users(:closer).id }
    assert_response 200
    assert_not_nil assigns(:ability)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:your_ability)
  end

  test 'should get show for other user when not logged in' do
    sign_out :user
    get :show, params: { id: 'unrestricted', for: users(:closer).id }
    assert_response 200
    assert_not_nil assigns(:ability)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:your_ability)
  end
end
