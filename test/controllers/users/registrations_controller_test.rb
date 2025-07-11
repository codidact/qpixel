require 'test_helper'

class Users::RegistrationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ApplicationHelper

  setup :devise_setup

  test 'should register user' do
    try_register_user('test', 'test@example.com', 'testtest')
    assert_response(:found)
    assert_not_nil assigns(:user).id
    assert_redirected_to root_path
  end

  test 'should prevent rapid registrations from same IP' do
    User.create(username: 'test', email: 'test2@example.com', password: 'testtest', current_sign_in_ip: '0.0.0.0')
    try_register_user('test', 'test@example.com', 'testtest')
    assert_response(:found)
    assert_redirected_to users_path
    assert_not_nil flash[:danger]
  end

  test 'ensure Devise errors are handled properly' do
    existing_user = users(:standard_user)
    try_register_user(existing_user.username, existing_user.email, 'testtest')
    assert_response(:success)
    assert_not_empty assigns(:user).errors
  end

  test 'should show deletion information page' do
    sign_in users(:standard_user)
    session[:sudo] = DateTime.now.iso8601
    get :delete
    assert_response(:success)
  end

  test 'should require authentication for deletion information' do
    get :delete
    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'should require sudo for deletion information' do
    sign_in users(:standard_user)
    get :delete
    assert_response(:found)
    assert_redirected_to user_sudo_path
  end

  test 'should delete user account' do
    sign_in users(:standard_user)
    session[:sudo] = DateTime.now.iso8601
    post :do_delete, params: { username: users(:standard_user).username }
    assert_response(:found)
    assert_redirected_to root_path
    assert_equal 'Sorry to see you go!', flash[:info]
    assert assigns(:user).deleted
  end

  test 'should require authentication to delete user account' do
    post :do_delete, params: { username: 'anything' }
    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'should require sudo to delete user account' do
    sign_in users(:standard_user)
    post :do_delete, params: { username: 'anything' }
    assert_response(:found)
    assert_redirected_to user_sudo_path
  end

  test 'should prevent deletion if username is incorrect' do
    sign_in users(:standard_user)
    session[:sudo] = DateTime.now.iso8601
    post :do_delete, params: { username: 'wrong' }
    assert_response(:success)
    assert_equal [I18n.t('users.errors.self_delete_wrong_username')], assigns(:user).errors.full_messages
    assert_not assigns(:user).deleted
  end

  test 'should prevent self-deletion if the user is at least a moderator' do
    locale_string_map = {
      moderator: 'users.errors.no_mod_self_delete',
      admin: 'users.errors.no_admin_self_delete'
    }

    [:moderator, :admin].each do |name|
      sign_in users(name)
      session[:sudo] = DateTime.now.iso8601

      try_do_delete_user(users(name))

      assert_response(:success)
      assert_equal [I18n.t(locale_string_map[name])], assigns(:user).errors.full_messages
      assert_not assigns(:user).deleted
    end
  end

  private

  # Attempts to sudo delete a given user
  # @param user [User] user to delete
  def try_do_delete_user(user)
    post :do_delete, params: { username: user.username }
  end

  def try_register_user(username, email, password)
    post :create, params: { user: { username: username, email: email, password: password,
                                    password_confirmation: password } }
  end

  def devise_setup
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end
end
