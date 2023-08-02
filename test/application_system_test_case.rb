require 'test_helper'

# This class serves as the base for all system test cases.
#
# The DRIVER environment variable is used to determine the browser that is used. Possible options are:
# - headless_chrome
# - chrome
# - headless_firefox (default)
# - firefox
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  DRIVER = if ENV['DRIVER']
             ENV['DRIVER'].to_sym
           else
             :headless_firefox
           end

  driven_by :selenium, using: DRIVER, screen_size: [1920, 1080]

  setup do
    Community.first.update(host: root_url.gsub(/https?:\/\//, '').gsub('/', ''))
  end

  # Logs in as the specified user
  #
  # @param user_or_fixture [User, Symbol] either a user or a symbol referring to a user from the fixtures
  # @param password [String] the password to sign in with
  def log_in(user_or_fixture, password = 'test123')
    @user = user(user_or_fixture)
    visit new_user_session_url
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: password

    click_button 'Sign in'
  end

  # Attempts to log out using the buttons in the top menu bar.
  def log_out
    within :css, '.header' do
      find(:css, 'i.far.fa-caret-square-down').find(:xpath, '..').click
    end

    find_link('Sign Out').click
  end

  # Pretends the user has clicked the confirmation link in the email they received.
  #
  # @param user_or_fixture [User, Symbol] the user or a symbol referring to the user fixture to use
  def confirm_email(user_or_fixture)
    u = user(user_or_fixture)
    visit user_confirmation_url(
      params: { confirmation_token: u.confirmation_token }
    )
  end

  # Translates the given parameter to a proper user.
  #
  # @param user_or_fixture [User, Symbol] either a user or a symbol referring to a fixture
  def user(user_or_fixture)
    if user_or_fixture.is_a? User
      user_or_fixture
    else
      users(user_or_fixture)
    end
  end
end
