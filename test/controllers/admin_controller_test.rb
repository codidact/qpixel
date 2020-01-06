require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  
  @parameterless_actions = [:index, :error_reports, :privileges]

  test "should get index" do
    sign_in users(:admin)
    get :index
    assert_response :success
  end

  test "should deny anonymous users access" do
    sign_out :user
    @parameterless_actions.each do |path|
      get path
      assert_response(404)
    end
  end

  test "should deny standard users access" do
    sign_in users(:standard_user)
    @parameterless_actions.each do |path|
      get path
      assert_response(404)
    end
  end

  test "should deny editors access" do
    sign_in users(:editor)
    @parameterless_actions.each do |path|
      get path
      assert_response(404)
    end
  end

  test "should deny deleters access" do
    sign_in users(:deleter)
    @parameterless_actions.each do |path|
      get path
      assert_response(404)
    end
  end

  test "should deny moderators access" do
    sign_in users(:moderator)
    @parameterless_actions.each do |path|
      get path
      assert_response(404)
    end
  end
end
