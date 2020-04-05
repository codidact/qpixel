require 'test_helper'

class SuspiciousVotesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get suspicious vote index' do
    sign_in users(:moderator)
    get :index
    assert_not_nil assigns(:suspicious_votes)
    assert_response(200)
  end

  test 'should get suspicious votes per user' do
    sign_in users(:moderator)
    get :user, params: { id: users(:standard_user).id }
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:from)
    assert_not_nil assigns(:to)
    assert_response(200)
  end

  test 'should require authentication to access index' do
    sign_out :user
    get :index
    assert_nil assigns(:suspicious_votes)
    assert_response(404)
  end

  test 'should require authentication to access user votes' do
    sign_out :user
    get :user, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_nil assigns(:from)
    assert_nil assigns(:to)
    assert_response(404)
  end

  test 'should require moderator status to access index' do
    sign_in users(:standard_user)
    get :index
    assert_nil assigns(:suspicious_votes)
    assert_response(404)
  end

  test 'should require moderator status to access user votes' do
    sign_in users(:standard_user)
    get :user, params: { id: users(:standard_user).id }
    assert_nil assigns(:user)
    assert_nil assigns(:from)
    assert_nil assigns(:to)
    assert_response(404)
  end
end
