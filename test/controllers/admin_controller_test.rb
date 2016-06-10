require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get index" do
    sign_in users(:admin)
    get :index
    assert_response :success
  end

  test "should deny anonymous users access" do
    sign_out :user
    AdminController.action_methods.each do |path|
      assert_raises ActionController::RoutingError do
        get path
      end
    end
  end

  test "should deny standard users access" do
    sign_in users(:standar_user)
    AdminController.action_methods.each do |path|
      assert_raises ActionController::RoutingError do
        get path
      end
    end
  end

  test "should deny editors access" do
    sign_in users(:editor)
    AdminController.action_methods.each do |path|
      assert_raises ActionController::RoutingError do
        get path
      end
    end
  end

  test "should deny deleters access" do
    sign_in users(:deleter)
    AdminController.action_methods.each do |path|
      assert_raises ActionController::RoutingError do
        get path
      end
    end
  end

  test "should deny moderators access" do
    sign_in users(:moderator)
    AdminController.action_methods.each do |path|
      assert_raises ActionController::RoutingError do
        get path
      end
    end
  end
end
