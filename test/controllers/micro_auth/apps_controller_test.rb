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

    try_create_oauth_app

    assert_response(:found)

    @app = assigns(:app)
    assert_not_nil @app
    assert_redirected_to oauth_app_path(@app.app_id)
  end

  test 'only owners or admins should be able to update apps' do
    app = micro_auth_apps(:owned_by_standard)

    [:standard_user, :global_admin, :editor].each do |name|
      updater = users(name)

      sign_in updater

      post update_oauth_app_path(app.app_id), params: {
        micro_auth_app: { name: 'Updated name' }
      }

      if app.user.same_as?(updater) || updater.admin?
        assert_response(:found, "Expected #{updater.username} to be able to update the app")
        assert_redirected_to oauth_app_path(app.app_id)
      else
        assert_response(:not_found)
      end
    end
  end

  private

  def try_create_oauth_app(name: 'MyApp', description: 'test MicroAuth App', auth_domain: 'localhost')
    post create_oauth_app_path, params: {
      micro_auth_app: {
        auth_domain: auth_domain,
        name: name,
        description: description
      }
    }
  end
end
