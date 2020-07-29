require 'test_helper'

class ModeratorControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index' do
    sign_in users(:moderator)
    get :index
    assert_response(200)
  end

  test 'should require authentication to access pages' do
    sign_out :user
    [:index, :recently_deleted_posts].each do |path|
      get path
      assert_response(404)
    end
  end

  test 'should require moderator status to access pages' do
    sign_in users(:standard_user)
    [:index, :recently_deleted_posts].each do |path|
      get path
      assert_response(404)
    end
  end
end
