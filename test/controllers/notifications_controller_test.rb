require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get index as JSON" do
    sign_in users(:standard_user)
    get :index, :format => :json
    assert_not_nil assigns(:notifications)
    assert_response(200)
  end
end
