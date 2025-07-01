require 'test_helper'

class Users::RegistrationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ApplicationHelper

  test 'should register user' do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    try_register_user('test', 'test@example.com', 'testtest')
    assert_response(:found)
    assert_not_nil assigns(:user).id
    assert_redirected_to root_path
  end

  test 'should prevent rapid registrations from same IP' do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    User.create(username: 'test', email: 'test2@example.com', password: 'testtest', current_sign_in_ip: '0.0.0.0')
    try_register_user('test', 'test@example.com', 'testtest')
    assert_response(:found)
    assert_redirected_to users_path
    assert_not_nil flash[:danger]
  end

  test 'ensure Devise errors are handled properly' do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    existing_user = users(:standard_user)
    try_register_user(existing_user.username, existing_user.email, 'testtest')
    assert_response(:success)
    assert_not_empty assigns(:user).errors
  end

  private

  def try_register_user(username, email, password)
    post :create, params: { user: { username: username, email: email, password: password,
                                    password_confirmation: password } }
  end
end
