require 'test_helper'

class ErrorsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "should provide 404 response" do
    get :not_found
    assert_response(404)
  end

  test "should provide 403 response" do
    get :forbidden
    assert_response(403)
  end

  test "should provide 409 response" do
    get :conflict
    assert_response(409)
  end

  test "should provide 422 response" do
    get :unprocessable_entity
    assert_response(422)
  end

  test "should provide 500 response" do
    get :internal_server_error
    assert_response(500)
  end
end
