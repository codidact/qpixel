require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index as JSON' do
    sign_in users(:standard_user)
    get :index, params: { format: :json }
    assert_not_nil assigns(:notifications)
    assert_response(200)
  end

  test 'should mark notification as read' do
    sign_in users(:standard_user)
    post :read, params: { id: notifications(:one).id, format: :json }
    assert_not_nil assigns(:notification)
    assert_equal true, assigns(:notification).is_read
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response(200)
  end

  test 'should mark all notifications as read' do
    sign_in users(:standard_user)
    post :read_all, params: { format: :json }
    assert_not_nil assigns(:notifications)
    assigns(:notifications).each do |notification|
      assert_equal true, notification.is_read
    end
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response(200)
  end

  test 'should prevent users marking others notifications read' do
    sign_in users(:editor)
    post :read, params: { id: notifications(:one).id, format: :json }
    assert_response(403)
  end

  test 'should require authentication to get index' do
    sign_out :user
    get :index, params: { format: :json }
    assert_response(401) # Devise seems to respond 401 for JSON requests.
  end
end
