require 'application_system_test_case'

class LoginTest < ApplicationSystemTestCase
  test 'User can register a new account and sign-in to it after confirming their email' do
    email = 'test@test.com'
    username = 'Test User'
    password = 'login_test_1'

    # Sign up for an account
    visit root_url
    click_on 'Sign Up'
    fill_in 'Email', with: email
    fill_in 'Username', with: username
    fill_in 'Password', with: password
    fill_in 'Password confirmation', with: password

    assert_difference 'User.count' do
      click_on 'Sign up'
    end

    user = User.last

    # Try logging in directly, this should fail because not confirmed yet
    log_in user, password
    assert_selector '.notice', text: 'You have to confirm your email address before continuing.'

    # Confirm email and sign in again, should succeed this time
    confirm_email user
    log_in user, password
    assert_selector '.notice', text: 'Signed in successfully.'
  end

  test 'User can sign in and is redirected back to the page they were on' do
    # Start on the users page
    visit users_url

    # Click the sign in button (top right)
    # Don't go through log_in helper, since we want to test the sign-in fully here
    click_on 'Sign In'
    fill_in 'Email', with: users(:standard_user).email
    fill_in 'Password', with: 'test123'
    click_button 'Sign in'

    # We should see a message that we have signed in, and we should be on the users page again.
    assert_selector '.notice', text: 'Signed in successfully.'
    assert_current_path users_url
  end

  test 'User can sign out' do
    log_in :standard_user
    assert_selector '.notice', text: 'Signed in successfully.'

    log_out
    assert_selector '.notice', text: 'Signed out successfully.'
  end
end
