require 'test_helper'

class UsersRegistrationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  tests Users::RegistrationsController

  test "should initialize user repuatation to 1 on create" do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    sign_out :user
    post :create, params: { user: { email: "new@qpixel-test.net", password: "ABCDEFGH", password_confirmation: "ABCDEFGH", username: "ABCDEF" } }
    assert_not assigns(:user).nil?
    assert_equal 1, assigns(:user).reputation
    assert_response(302)
  end
end
