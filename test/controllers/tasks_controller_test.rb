require 'test_helper'

class TasksControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should deny access to anonymous users' do
    get '/maintenance'
    assert_response 403
  end

  test 'should deny access to non-developers' do
    sign_in users(:admin)
    get '/maintenance'
    assert_response 403
  end

  test 'should grant access to developers' do
    sign_in users(:developer)
    get '/maintenance'
    assert_response 200
  end
end
