require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should deny access to anonymous users' do
    [:users, :posts, :subscriptions].each do |route|
      get route
      assert_response :found
      assert_redirected_to new_user_session_path
    end
  end

  test 'should deny access to non-moderators' do
    sign_in users(:standard_user)
    [:users, :posts, :subscriptions].each do |route|
      get route
      assert_response :not_found
    end
  end

  test 'every route should work for moderators' do
    sign_in users(:moderator)
    [:users, :posts, :subscriptions].each do |route|
      get route
      assert_response :success
    end
  end

  test 'every global route should work for global moderators & admins' do
    sign_in users(:global_admin)
    [:users_global, :subs_global, :posts_global].each do |route|
      get route
      assert_response :success
    end
  end
end
