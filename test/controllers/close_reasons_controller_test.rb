require 'test_helper'

class CloseReasonsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  PARAM_LESS_ACTIONS = [:index, :new].freeze

  test 'should get index' do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert_not_nil assigns(:close_reasons)
  end

  test 'should deny anonymous users access' do
    sign_out :user
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(404)
    end
  end

  test 'should deny standard users access' do
    sign_in users(:standard_user)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(404)
    end
  end

  test 'should get new' do
    sign_in users(:global_admin)
    get :new
    assert_response :success
    assert_not_nil assigns(:close_reason)
  end

  test 'should create close reason' do
    sign_in users(:global_admin)
    post :create, params: { close_reason: { name: 'test', description: 'test', requires_other_post: true,
                                            active: true } }
    assert_response 302
    assert_redirected_to close_reasons_path
    assert_not_nil assigns(:close_reason)
    assert_not_nil assigns(:close_reason).id
  end

  test 'should get edit' do
    sign_in users(:global_admin)
    get :edit, params: { id: close_reasons(:duplicate).id }
    assert_response 200
    assert_not_nil assigns(:close_reason)
  end

  test 'should update close reason' do
    sign_in users(:global_admin)
    patch :update, params: { id: close_reasons(:duplicate).id, close_reason: { name: 'test', description: 'test',
                                                                               requires_other_post: true,
                                                                               active: false } }
    assert_response 302
    assert_redirected_to close_reasons_path
    assert_not_nil assigns(:close_reason)
    assert_equal false, assigns(:close_reason).active
  end
end
