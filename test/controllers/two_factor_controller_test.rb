require 'test_helper'

class TwoFactorControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'enable_2fa should correctly enable app 2FA' do
    user = users(:standard_user)
    sign_in user

    try_enable_2fa('app')
    user.reload

    @secret = assigns('secret')
    @app_name = assigns('app_name')
    @qr_uri = assigns('qr_uri')

    assert_not_nil(@secret)
    assert_not_nil(@app_name)
    assert_not_nil(@qr_uri)

    assert @app_name.end_with?(AppConfig.server_settings['network_base_domain'])
    assert_equal user.two_factor_token, @secret
    assert_equal user.two_factor_method, 'app'
  end

  private

  def try_enable_2fa(method, **opts)
    post :enable_2fa, params: {
      method: method
    }.merge(opts)
  end
end
