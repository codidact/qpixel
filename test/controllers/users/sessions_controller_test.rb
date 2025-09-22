require 'test_helper'

class Users::SessionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ApplicationHelper

  test 'should sign in with 2fa backup code' do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    Users::SessionsController.first_factor << users(:enabled_2fa).id

    try_verify_2fa_code(users(:enabled_2fa))

    assert_response(:found)
    assert_not_nil flash[:warning]
    assert_not_nil current_user
    assert_nil current_user.backup_2fa_code
    assert_not current_user.enabled_2fa
  end

  test 'should remember users with 2FA if requested' do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    Users::SessionsController.first_factor << users(:enabled_2fa).id

    try_verify_2fa_code(users(:enabled_2fa), remember_me: true)

    assert_response(:found)
    assert_not_nil current_user
    assert @controller.remember_me_is_active?(current_user)
  end

  private

  # @param user [User] user to very code for
  def try_verify_2fa_code(user, **opts)
    post :verify_code, params: { uid: user.id, code: 'M8lENyehyCvo9F9MbyTl1aOL' }.merge(opts)
  end
end
