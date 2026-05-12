require 'test_helper'

class Users::SessionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ApplicationHelper

  setup :set_mapping

  test 'should sign in with 2fa backup code' do
    Users::SessionsController.first_factor << users(:enabled_2fa).id

    try_verify_2fa_code(users(:enabled_2fa))

    assert_response(:found)
    assert_not_nil flash[:warning]
    assert_not_nil current_user
    assert_nil current_user.backup_2fa_code
    assert_not current_user.enabled_2fa
  end

  test 'should remember users with 2FA if requested' do
    Users::SessionsController.first_factor << users(:enabled_2fa).id

    try_verify_2fa_code(users(:enabled_2fa), remember_me: true)

    assert_response(:found)
    assert_not_nil current_user
    assert @controller.remember_me_is_active?(current_user)
  end

  test 'should redirect users with code-based 2FA to code verification' do
    pass = 'temp password for testing manual 2FA signin'
    user = users(:enabled_2fa)
    user.update!(password: pass)

    post :create, params: { user: { email: user.email, password: pass } }

    assert_response(:found)
    assert_nil flash[:notice]
    assert_redirected_to(login_verify_2fa_path(uid: user.id, remember_me: false))
  end

  private

  def set_mapping
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  # @param user [User] user to verify code for
  # @param opts [Hash] options hash - any additional optional params to merge in
  def try_verify_2fa_code(user, **opts)
    post :verify_code, params: { uid: user.id, code: 'M8lENyehyCvo9F9MbyTl1aOL' }.merge(opts)
  end
end
