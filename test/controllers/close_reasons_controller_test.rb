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
end
