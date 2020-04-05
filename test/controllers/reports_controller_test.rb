require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should deny access to anonymous users' do
    [:users, :posts, :subscriptions].each do |route|
      get route
      assert_response 302
      assert_redirected_to new_user_session_path
    end
  end

  test 'should deny access to non-moderators' do
    sign_in users(:standard_user)
    [:users, :posts, :subscriptions].each do |route|
      get route
      assert_response 404
    end
  end

  test 'every route should work for moderators' do
    sign_in users(:moderator)
    [:users, :posts, :subscriptions].each do |route|
      get route
      assert_response 200
    end
  end
end
