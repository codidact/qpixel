require 'test_helper'

class MicroAuth::AuthenticationControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'token should correctly handle missing apps' do
    post oauth_token_path, params: {
      app_id: 'i_do_not_exist',
      secret: SecureRandom.base58(32),
      format: :json
    }

    assert_response(:bad_request)
    assert_valid_json_response
    res_body = JSON.parse(response.body)
    error = res_body['error']
    assert_equal 'app_mismatch', error['type']
    assert_not_nil error['message']
  end

  test 'token should correctly handle missing tokens' do
    app = micro_auth_apps(:owned_by_standard)

    post oauth_token_path, params: {
      app_id: app.app_id,
      secret: app.secret_key,
      code: 'this_is_not_the_code_you_are_looking_for',
      format: :json
    }

    assert_response(:bad_request)
    assert_valid_json_response
    res_body = JSON.parse(response.body)
    error = res_body['error']
    assert_equal 'token_mismatch', error['type']
    assert_not_nil error['message']
  end
end
