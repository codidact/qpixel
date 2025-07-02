require 'test_helper'

class SudoControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should require auth before sudo mode' do
    get :sudo
    assert_response(:found)
    assert_redirected_to new_user_session_path
  end

  test 'should show sudo mode page' do
    sign_in users(:standard_user)
    get :sudo
    assert_response(:success)
  end

  test 'should fail sudo mode with wrong password' do
    sign_in users(:standard_user)
    post :enter_sudo, params: { password: 'wrong' }
    assert_response(:success)
    assert_equal 'The password you entered was incorrect.', flash[:danger]
  end

  test 'should enter sudo mode' do
    set_password(users(:standard_user), 'test1234')
    sign_in users(:standard_user)
    session[:sudo_return] = users_me_path
    post :enter_sudo, params: { password: 'test1234' }
    assert_response(:found)
    assert_redirected_to users_me_path
    assert_not_nil session[:sudo]
    assert_nothing_raised do
      DateTime.iso8601(session[:sudo])
    end
  end

  private

  def set_password(user, password)
    user.password = password
    user.skip_reconfirmation!
    user.save!
  end
end
