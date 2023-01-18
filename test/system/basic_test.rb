require "application_system_test_case"

class BasicTest < ApplicationSystemTestCase
  test 'newly registered user can sign in after confirming their account' do
    email = 'test@test.com'
    username = 'Test User'
    password = 'test123'

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

    confirm_email user
    log_in user, password
    assert_selector '.notice', text: 'Signed in successfully.'
  end
end
