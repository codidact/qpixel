require 'test_helper'

class Users::RegistrationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ApplicationHelper

  setup :devise_setup

  test ':create should correctly register user' do
    try_register_user('test', 'test@example.com', 'testtest')

    assert_response(:found)
    assert_redirected_to root_path

    @user = assigns(:user)
    assert_not_nil @user
    assert_not_nil @user.id
    assert_operator 1.minute.ago, :<, @user.created_at
  end

  test ':create should prevent rapid registration from the same IP' do
    ensure_user_already_exists
    try_register_user('test', 'test@example.com', 'testtest')

    assert_response(:found)
    assert_redirected_to users_path
    assert_not_nil flash[:danger]
  end

  test ':create should skip registration rate limit in dev env' do
    Rails.env.stub(:development?, true) do
      ensure_user_already_exists
      try_register_user('test', 'test@example.com', 'testtest')

      assert_response(:found)
      assert_redirected_to root_path
    end
  end

  test ':create should correctly handle Devise errors' do
    existing_user = users(:standard_user)
    try_register_user(existing_user.username, existing_user.email, 'testtest')

    assert_response(:success)
    assert_not_empty assigns(:user).errors
  end

  test ':delete should show deletion information page' do
    sign_in users(:standard_user)
    session[:sudo] = DateTime.now.iso8601
    get :delete
    assert_response(:success)
  end

  test ':delete should require authentication' do
    get :delete
    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test ':delete should require sudo' do
    sign_in users(:standard_user)
    get :delete
    assert_response(:found)
    assert_redirected_to user_sudo_path
  end

  test 'should delete user account' do
    sign_in users(:standard_user)
    session[:sudo] = DateTime.now.iso8601
    try_do_delete_user(users(:standard_user))

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
      admin: 'users.errors.no_admin_self_delete',
      enabled_2fa: 'users.errors.no_2fa_self_delete'
    }

    [:moderator, :admin, :enabled_2fa].each do |name|
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

  def ensure_user_already_exists
    User.create(username: 'test',
                email: 'test2@example.com',
                password: 'testtest',
                current_sign_in_ip: '0.0.0.0',
                created_at: 1.second.ago.utc)
  end

  def devise_setup
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end
end
