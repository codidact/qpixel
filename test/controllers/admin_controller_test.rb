require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  PARAM_LESS_ACTIONS = [:index, :error_reports, :privileges].freeze

  test 'should get index' do
    sign_in users(:admin)
    get :index
    assert_response :success
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

  test 'should deny editors access' do
    sign_in users(:editor)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(404)
    end
  end

  test 'should deny deleters access' do
    sign_in users(:deleter)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(404)
    end
  end

  test 'should deny moderators access' do
    sign_in users(:moderator)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(404)
    end
  end

  test 'should deny admins access to non-admin community' do
    RequestContext.community = Community.create(host: 'other.qpixel.com', name: 'Other')
    request.env['HTTP_HOST'] = 'other.qpixel.com'
    sign_in users(:admin)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(404)
    end
  end

  test 'should grant global admims access to non admin community' do
    RequestContext.community = Community.create(host: 'other.qpixel.com', name: 'Other')
    request.env['HTTP_HOST'] = 'other.qpixel.com'
    sign_in users(:global_admin)
    PARAM_LESS_ACTIONS.each do |path|
      get path
      assert_response(200)
    end
  end

  test 'should get single privilege' do
    sign_in users(:admin)
    get :show_privilege, params: { name: privileges(:close).name, format: :json }
    assert_response 200
    assert_not_nil assigns(:privilege)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
  end

  test 'should update privilege threshold' do
    sign_in users(:admin)
    post :update_privilege, params: { name: privileges(:close).name, threshold: 2000 }
    assert_response 202
    assert_not_nil assigns(:privilege)
    assert_equal 2000, assigns(:privilege).threshold
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'OK', JSON.parse(response.body)['status']
  end

  test 'should access error reports' do
    sign_in users(:admin)
    get :error_reports
    assert_response 200
    assert_not_nil assigns(:reports)
  end
end
