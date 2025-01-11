require 'test_helper'

class Users::SessionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ApplicationHelper

  test 'should sign in with 2fa backup code' do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    Users::SessionsController.first_factor << users(:enabled_2fa).id
    post :verify_code, params: { uid: users(:enabled_2fa).id, code: 'M8lENyehyCvo9F9MbyTl1aOL' }
    assert_response 302
    assert_not_nil flash[:warning]
    assert_not_nil current_user
    assert_nil current_user.backup_2fa_code
    assert_not current_user.enabled_2fa
  end
end
