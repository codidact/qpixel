require 'test_helper'

class MicroAuth::AppsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should require authentication to create apps' do
    post create_oauth_app_path

    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'should correctly create apps' do
    sign_in users(:standard_user)

    post create_oauth_app_path, params: {
      micro_auth_app: {
        auth_domain: 'localhost',
        name: 'MyApp',
        description: 'testing app'
      }
    }

    assert_response(:found)

    @app = assigns(:app)
    assert_not_nil @app
    assert_redirected_to oauth_app_path(@app.app_id)
  end
end
